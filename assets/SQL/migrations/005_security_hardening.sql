-- =============================================================================
-- MIGRATION 005 — Vá lỗ hổng bảo mật RLS/RPC (Giai đoạn 5)
--
-- Chạy SAU 004_account_deletion_and_storage.sql. Idempotent (chạy lại nhiều lần
-- không lỗi). Toàn bộ nằm trong một transaction begin; ... commit;
--
-- Đây là app tài chính: chính xác là tối quan trọng. Migration này KHÔNG đổi
-- logic nghiệp vụ; chỉ siết quyền để không ai chạm được dữ liệu/số dư của người
-- khác qua PostgREST.
--
-- Tóm tắt các mục vá:
--   P0-1  REVOKE execute mọi hàm helper NỘI BỘ khỏi public/anon/authenticated.
--         Mặc định Supabase cho anon/authenticated execute MỌI hàm schema coinsort;
--         apply_balance_delta() (security definer, không tự kiểm quyền) vì thế bị
--         lộ ra ngoài → bất kỳ ai gọi để đặt lại số dư ví người khác.
--   P0-2  transactions: with check khi INSERT/UPDATE phải bảo đảm account_id (và
--         to_account_id) là ví CỦA MÌNH hoặc ví CHUNG của nhóm, created_by là
--         chính mình, paid_by là thành viên nhóm — không cho ghi thẳng vào ví
--         người khác.
--   P0-3  group_settlements: tách policy FOR ALL "chỉ cần là thành viên" thành
--         SELECT (thành viên) + INSERT/UPDATE/DELETE (chỉ from_user/created_by).
--   P0-5  get_email_for_login: bỏ khớp theo full_name (không unique) → chỉ khớp
--         username chính xác hoặc email. Chặn dò email của người khác bằng tên.
--   P1-5  users: thêm policy SELECT cho phép đọc hồ sơ của thành viên CÙNG NHÓM.
--   P2-2  get_budget_progress: thêm _assert_group_member khi có nhóm.
--   P2-3  handle_new_user: bổ sung set search_path = coinsort, public, extensions.
--   P2-4  storage receipts: thêm giới hạn size/MIME ở bucket. KHÔNG nới lỏng
--         SELECT cho thành viên nhóm được vì image_url do client tự đặt và không
--         ràng buộc → xem chi tiết phần P2-4 (cần đổi cách lưu path phía app).
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- P2-3 — handle_new_user: set search_path = coinsort, public, extensions
-- ---------------------------------------------------------------------------
-- Trigger chạy trên auth.users. Thiếu search_path cố định → có thể bị dẫn dụ
-- phân giải tên bảng sai (search_path do phiên đặt). Giữ NGUYÊN thân hàm, chỉ
-- thêm `set search_path = coinsort, public, extensions`. Không đụng tới trigger on_auth_user_created
-- (nó tham chiếu hàm theo tên nên create or replace là đủ).
create or replace function coinsort.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  personal_group_id uuid;
begin
  insert into coinsort.users (id, full_name, avatar_url, username, role, status)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    coalesce(new.raw_user_meta_data->>'username', 'user_' || left(new.id::text, 8)),
    'user',
    'active'
  );

  insert into coinsort.groups (name, is_personal, status)
  values ('Chi tiêu cá nhân', true, 'active')
  returning id into personal_group_id;

  insert into coinsort.group_members (group_id, user_id, role, status)
  values (personal_group_id, new.id, 'admin', 'active');

  insert into coinsort.accounts (user_id, name, account_type, balance, opening_balance, currency, status)
  values
    (new.id, 'Tiền mặt', 'asset', 0, 0, 'VND', 'active'),
    (new.id, 'Tài khoản Ngân hàng', 'asset', 0, 0, 'VND', 'active');

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- P0-5 — get_email_for_login: chỉ khớp username hoặc email
-- ---------------------------------------------------------------------------
-- Hàm này granted cho anon vì luồng đăng nhập gọi khi CHƯA đăng nhập
-- (lib/src/features/auth/data/auth_repository.dart -> signInWithEmailOrUsername).
-- Vì vậy vẫn giữ grant cho anon, nhưng siết logic:
--   * Bỏ hoàn toàn nhánh khớp theo full_name: full_name KHÔNG unique và cho phép
--     kẻ tấn công dò ra email của người khác chỉ bằng tên hiển thị.
--   * Chỉ khớp theo username (cột UNIQUE → tối đa một kết quả) hoặc trả lại chính
--     email nếu người dùng đã nhập email.
--   * Bỏ qua tài khoản đã xoá (status != 'active').
create or replace function coinsort.get_email_for_login(login_id text)
returns text
language plpgsql
security definer
set search_path = coinsort, public, extensions
as $$
declare
  result text;
begin
  login_id := trim(login_id);
  if login_id = '' then return null; end if;

  -- Người dùng nhập sẵn email → trả lại nguyên văn, không tra bảng.
  if position('@' in login_id) > 0 then return login_id; end if;

  -- Chỉ khớp username chính xác (UNIQUE). KHÔNG khớp theo full_name.
  select u.email into result
  from auth.users u
  inner join coinsort.users p on p.id = u.id
  where p.username = login_id
    and coalesce(p.status, 'active') = 'active'
  limit 1;

  return result;
end;
$$;
-- Luồng đăng nhập chạy ở trạng thái anon nên buộc phải giữ grant cho anon.
grant execute on function coinsort.get_email_for_login(text) to anon;
grant execute on function coinsort.get_email_for_login(text) to authenticated;

-- ---------------------------------------------------------------------------
-- P2-2 — get_budget_progress: kiểm tra thành viên nhóm
-- ---------------------------------------------------------------------------
-- Giữ NGUYÊN toàn bộ logic của migration 003, chỉ thêm _assert_group_member khi
-- p_group_id không null (spent được tính theo giao dịch của nhóm). Ngân sách cá
-- nhân (p_group_id null) không cần kiểm tra nhóm: b.user_id = auth.uid() đã giới
-- hạn về ngân sách của chính người gọi, và điều kiện t.group_id = null không bao
-- giờ khớp nên spent = 0 (giữ đúng hành vi cũ khi truyền null).
create or replace function coinsort.get_budget_progress(p_group_id uuid)
returns table (
  budget_id     uuid,
  category_id   uuid,
  category_name text,
  color_hex     text,
  icon_name     text,
  amount        numeric,
  spent         numeric,
  period        text,
  start_date    date,
  end_date      date
)
language plpgsql
security definer
set search_path = coinsort, public, extensions
stable
as $$
begin
  if p_group_id is not null then
    perform coinsort._assert_group_member(p_group_id);
  end if;

  return query
  select
    b.id, b.category_id,
    coalesce(c.name, 'Khác')::text,
    coalesce(c.color_hex, '#A0A0A0')::text,
    coalesce(c.icon_name, 'category')::text,
    b.amount,
    coalesce((
      select sum(t.amount) from coinsort.transactions t
      where t.group_id = p_group_id
        and t.category_id = b.category_id
        and t.type = 'expense'
        and coalesce(t.row_status, 'active') = 'active'
        and t.transaction_date >= b.start_date
        and t.transaction_date < (b.end_date + 1)
    ), 0)::numeric,
    b.period, b.start_date, b.end_date
  from coinsort.budgets b
  left join coinsort.categories c on c.id = b.category_id
  where b.user_id = auth.uid()
    and coalesce(b.status, 'active') = 'active'
  order by b.start_date desc;
end;
$$;
grant execute on function coinsort.get_budget_progress(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- P1-5 — users: đọc hồ sơ thành viên cùng nhóm
-- ---------------------------------------------------------------------------
-- Hiện users chỉ có "Users can view own profile" (auth.uid() = id) nên khi hiển
-- thị tên/ảnh của thành viên khác phải đi qua RPC. Ta bổ sung một policy SELECT
-- cho phép đọc hồ sơ của user có chung ít nhất một nhóm đang hoạt động với người
-- gọi.
--
-- LƯU Ý KỸ THUẬT: policy SELECT hiện tại của group_members chỉ trả về CHÍNH các
-- dòng của người gọi (user_id = auth.uid()). Nếu viết subquery group_members
-- trực tiếp trong policy của users, RLS của group_members sẽ được áp lên subquery
-- đó và chỉ thấy dòng của chính mình → không bao giờ khớp thành viên khác. Vì vậy
-- ta dùng một hàm SECURITY DEFINER (bỏ qua RLS của group_members) chỉ trả về
-- boolean "hai người có chung nhóm không". Hàm chỉ trả boolean, không lộ dữ liệu
-- nhạy cảm, và bắt buộc để policy hoạt động nên được grant cho authenticated.
create or replace function coinsort.shares_group_with_me(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = coinsort, public, extensions
stable
as $$
  select exists (
    select 1
    from coinsort.group_members gm_me
    join coinsort.group_members gm_them
      on gm_them.group_id = gm_me.group_id
    where gm_me.user_id = auth.uid()
      and gm_me.status = 'active'
      and gm_them.user_id = p_user_id
      and gm_them.status = 'active'
  );
$$;
grant execute on function coinsort.shares_group_with_me(uuid) to authenticated;

drop policy if exists "Users can view group members profiles" on coinsort.users;
create policy "Users can view group members profiles"
  on coinsort.users for select
  using (coinsort.shares_group_with_me(id));
-- Ghi chú: RLS ở mức DÒNG, không giới hạn được theo CỘT. Policy này cho thành
-- viên cùng nhóm đọc cả dòng users (gồm full_name, username, avatar_url, và cả
-- is_premium/role/status — đều không phải bí mật; email KHÔNG nằm ở bảng này mà ở
-- auth.users). Nếu sau này cần giấu cột, phải dùng column privileges hoặc view
-- riêng — ngoài phạm vi bản vá này.

-- ---------------------------------------------------------------------------
-- P0-1 — REVOKE execute các hàm helper NỘI BỘ
-- ---------------------------------------------------------------------------
-- Trong Supabase, mọi hàm schema coinsort MẶC ĐỊNH có execute cho PUBLIC (kéo theo
-- anon + authenticated). Toàn repo trước đây không có một lệnh revoke nào, nên
-- các hàm nội bộ dưới đây bị lộ thẳng ra PostgREST. Đặc biệt apply_balance_delta
-- là security definer và KHÔNG tự kiểm tra quyền → bất kỳ ai cũng gọi được để
-- sửa số dư ví bất kỳ.
--
-- Các hàm này chỉ được gọi TỪ BÊN TRONG các hàm security definer khác (owner là
-- postgres) hoặc từ trigger. Owner vẫn giữ execute; revoke chỉ gỡ quyền của
-- public/anon/authenticated nên KHÔNG phá luồng gọi nội bộ và KHÔNG ảnh hưởng
-- trigger (trigger chạy không cần execute của người gọi). Các RPC mặt tiền mà
-- client cần (create_transaction, update_transaction, settle_up, get_analytics,
-- get_group_balances, delete_my_account, get_email_for_login, ...) KHÔNG bị đụng.
--
-- revoke là idempotent: gỡ một quyền không tồn tại không gây lỗi.

-- Helper sửa số dư — điểm duy nhất được phép chạm accounts.balance.
revoke execute on function coinsort.apply_balance_delta(uuid, numeric) from public, anon, authenticated;

-- Helper nghiệp vụ nhóm/chia tiền (bắt đầu bằng _).
revoke execute on function coinsort._assert_group_member(uuid) from public, anon, authenticated;
revoke execute on function coinsort._assert_account_usable(uuid, uuid) from public, anon, authenticated;
revoke execute on function coinsort._write_splits(uuid, uuid, text, numeric, jsonb) from public, anon, authenticated;

-- Sinh mã mời — chỉ dùng nội bộ trong create_group/rotate_invite_code.
revoke execute on function coinsort.gen_invite_code() from public, anon, authenticated;

-- Hàm trigger (trả về trigger; PostgREST không phơi ra như RPC, nhưng revoke cho
-- chắc chắn — phòng thủ theo chiều sâu). Việc revoke KHÔNG chặn trigger kích hoạt.
revoke execute on function coinsort.update_account_balance() from public, anon, authenticated;
revoke execute on function coinsort.touch_updated_at() from public, anon, authenticated;
revoke execute on function coinsort.log_transaction_change() from public, anon, authenticated;
revoke execute on function coinsort.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- P0-2 — transactions: siết with check khi ghi vào ví
-- ---------------------------------------------------------------------------
-- Policy cũ chỉ kiểm tra "là thành viên nhóm" nên một thành viên có thể chèn/sửa
-- giao dịch trỏ account_id vào ví CÁ NHÂN của người khác (không chia sẻ), qua đó
-- làm sai số dư ví đó (trigger update_account_balance sẽ áp delta lên ví bị trỏ).
--
-- Điều kiện ví hợp lệ nhân bản đúng logic _assert_account_usable: ví phải là ví
-- của chính người gọi (a.user_id = auth.uid()) HOẶC ví chung của đúng nhóm giao
-- dịch (a.group_id = transactions.group_id). Kết hợp với điều kiện người gọi là
-- thành viên nhóm nên an toàn tương đương RPC create_transaction/update_transaction.
--
-- Ứng dụng luôn ghi giao dịch QUA RPC (security definer, bỏ qua RLS) nên các
-- policy này chỉ chặn ghi thẳng qua PostgREST — không ảnh hưởng luồng bình thường.
-- created_by và paid_by ở schema là NOT NULL nên không cần nhánh null.

drop policy if exists "Users can insert group transactions" on coinsort.transactions;
create policy "Users can insert group transactions"
  on coinsort.transactions for insert
  with check (
    -- (a) người ghi là thành viên đang hoạt động của nhóm
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
    -- (b) created_by phải là chính người đang đăng nhập
    and transactions.created_by = auth.uid()
    -- (c) ví nguồn phải thuộc quyền dùng: ví của mình HOẶC ví chung của nhóm
    and exists (
      select 1 from coinsort.accounts a
      where a.id = transactions.account_id
        and coalesce(a.status, 'active') = 'active'
        and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
    )
    -- (d) ví đích (transfer) nếu có cũng phải hợp lệ
    and (
      transactions.to_account_id is null
      or exists (
        select 1 from coinsort.accounts a
        where a.id = transactions.to_account_id
          and coalesce(a.status, 'active') = 'active'
          and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
      )
    )
    -- (e) paid_by phải là thành viên nhóm
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = transactions.paid_by
        and gm.status = 'active'
    )
  );

drop policy if exists "Users can update group transactions" on coinsort.transactions;
create policy "Users can update group transactions"
  on coinsort.transactions for update
  using (
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  )
  with check (
    -- vẫn là giao dịch của nhóm mình
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
    -- ví nguồn sau khi sửa vẫn phải thuộc quyền dùng
    and exists (
      select 1 from coinsort.accounts a
      where a.id = transactions.account_id
        and coalesce(a.status, 'active') = 'active'
        and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
    )
    -- ví đích (transfer) nếu có cũng phải hợp lệ
    and (
      transactions.to_account_id is null
      or exists (
        select 1 from coinsort.accounts a
        where a.id = transactions.to_account_id
          and coalesce(a.status, 'active') = 'active'
          and (a.user_id = auth.uid() or a.group_id = transactions.group_id)
      )
    )
    -- paid_by vẫn phải là thành viên nhóm
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = transactions.group_id
        and gm.user_id = transactions.paid_by
        and gm.status = 'active'
    )
  );
-- Policy SELECT ("Users can view group transactions") và DELETE ("Users can
-- delete group transactions") giữ nguyên: chúng chỉ cho thành viên xem/xoá giao
-- dịch của nhóm mình, không mở đường ghi vào ví người khác.

-- ---------------------------------------------------------------------------
-- P0-3 — group_settlements: chống giả mạo quyết toán
-- ---------------------------------------------------------------------------
-- Policy cũ FOR ALL chỉ kiểm tra "là thành viên nhóm" → một thành viên bất kỳ có
-- thể chèn quyết toán mạo danh (from_user là người khác) hoặc sửa/xoá quyết toán
-- của người khác, làm sai công nợ. Tách thành các policy theo thao tác:
--   SELECT  : mọi thành viên nhóm xem được.
--   INSERT  : chỉ tạo được bản ghi mà from_user = mình (và created_by = mình).
--   UPDATE  : chỉ người tạo/from_user sửa được, và không đổi được sang người khác.
--   DELETE  : chỉ người tạo/from_user xoá được.
-- Ứng dụng ghi quyết toán qua RPC settle_up (security definer, bỏ qua RLS) và đọc
-- qua get_group_settlements nên siết RLS không ảnh hưởng luồng thường.
drop policy if exists "Members manage settlements" on coinsort.group_settlements;

drop policy if exists "Members can view settlements" on coinsort.group_settlements;
create policy "Members can view settlements"
  on coinsort.group_settlements for select
  using (
    exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

drop policy if exists "Members can create own settlements" on coinsort.group_settlements;
create policy "Members can create own settlements"
  on coinsort.group_settlements for insert
  with check (
    group_settlements.from_user = auth.uid()
    and (group_settlements.created_by is null or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

drop policy if exists "Creators can update own settlements" on coinsort.group_settlements;
create policy "Creators can update own settlements"
  on coinsort.group_settlements for update
  using (
    (group_settlements.from_user = auth.uid() or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  )
  with check (
    group_settlements.from_user = auth.uid()
    and (group_settlements.created_by is null or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

drop policy if exists "Creators can delete own settlements" on coinsort.group_settlements;
create policy "Creators can delete own settlements"
  on coinsort.group_settlements for delete
  using (
    (group_settlements.from_user = auth.uid() or group_settlements.created_by = auth.uid())
    and exists (
      select 1 from coinsort.group_members gm
      where gm.group_id = group_settlements.group_id
        and gm.user_id = auth.uid()
        and gm.status = 'active'
    )
  );

-- ---------------------------------------------------------------------------
-- P2-4 — storage receipts: giới hạn size/MIME (+ ghi chú giới hạn an toàn)
-- ---------------------------------------------------------------------------
-- 1) Ràng buộc size/MIME ở BUCKET (Supabase hỗ trợ qua storage.buckets). Khớp với
--    giới hạn 5MB và các định dạng ảnh mà app dùng (jpeg/png/webp/heic).
update storage.buckets
   set file_size_limit = 5242880,  -- 5 MB, khớp StorageService.maxBytes phía app
       allowed_mime_types = array['image/jpeg','image/png','image/webp','image/heic','image/heif']
 where id = 'receipts';

update storage.buckets
   set file_size_limit = 5242880,
       allowed_mime_types = array['image/jpeg','image/png','image/webp','image/heic','image/heif']
 where id = 'avatars';

-- 2) KHÔNG nới lỏng SELECT cho thành viên nhóm — CỐ Ý GIỮ NGUYÊN policy per-UID
--    "Users manage own receipts" của migration 004.
--
--    Vì sao không thể vá an toàn bằng SQL thuần:
--    - App lưu ảnh hoá đơn tại path "{uid}/{timestamp}.{ext}" và ghi CHÍNH path
--      đó (chuỗi tuỳ ý do client đặt) vào transactions.image_url.
--    - Một policy kiểu "cho đọc object nếu tồn tại transaction cùng nhóm có
--      image_url = storage.objects.name" NGHE có vẻ đúng nhưng TẠO LỖ HỔNG MỚI:
--      image_url do client đặt và KHÔNG bị ràng buộc phải khớp chủ sở hữu path.
--      Kẻ tấn công chỉ cần tạo một giao dịch trong nhóm của MÌNH với
--      image_url = "victimUID/....jpg" là mượn được quyền đọc hoá đơn của nạn
--      nhân (IDOR) — kể cả khi nạn nhân không ở trong nhóm đó.
--    - Do đó, theo nguyên tắc "thà giữ nguyên còn hơn mở toang", ta KHÔNG thêm
--      policy nới lỏng ở đây.
--
--    CẦN LÀM PHÍA APP (ngoài phạm vi file SQL này — việc của Dart):
--      * Đổi cách lưu path hoá đơn của giao dịch NHÓM sang theo nhóm, ví dụ
--        "receipts/{group_id}/{uid}/{timestamp}.{ext}", rồi mới thêm policy
--        SELECT trên storage.objects với điều kiện
--        (storage.foldername(name))[1] = group_id và người gọi là thành viên
--        active của group_id đó. Khi ấy quyền đọc gắn với NHÓM trong chính path
--        (không bịa được), an toàn để chia sẻ.
--      * Hoặc thêm cột riêng ánh xạ object -> transaction do server kiểm soát,
--        và chặn client tự đặt image_url trỏ tới path của người khác.
--    Trước khi làm được điều đó, hoá đơn của giao dịch nhóm chỉ người tải lên xem
--    được (đúng như hành vi hiện tại) — an toàn nhưng chưa chia sẻ được.

commit;
