-- =============================================================================
-- 000 — TẠO SCHEMA `coinsort` VÀ PHÂN QUYỀN NỀN
--
-- Chạy ĐẦU TIÊN trong Supabase Dashboard → SQL Editor (hoặc dùng INSTALL_ALL.sql
-- đã gộp sẵn). Idempotent.
--
-- Vì sao cần file này: mọi bảng/RPC của app nằm trong schema riêng `coinsort`
-- thay cho `public`. Với `public`, Supabase đã cài sẵn (1) grant usage cho
-- anon/authenticated/service_role và (2) default privileges để bảng/hàm/sequence
-- tạo mới tự có quyền cho các role đó. Schema tự tạo KHÔNG có gì cả → PostgREST
-- sẽ trả 42501 permission denied cho mọi truy vấn. Header này tái tạo đúng mặc
-- định ấy cho `coinsort`; migration 005 vẫn revoke chọn lọc các hàm nội bộ như cũ.
--
-- ⚠️  BƯỚC TAY BẮT BUỘC (không làm được bằng SQL này):
--     Dashboard → Project Settings → Data API → "Exposed schemas" → thêm `coinsort`
--     (giữ nguyên public, graphql_public). Không có bước này client nhận
--     "The schema must be one of the following: public, graphql_public".
--     Client Flutter đã đặt PostgrestClientOptions(schema: 'coinsort').
-- =============================================================================

create schema if not exists coinsort;

grant usage on schema coinsort to postgres, anon, authenticated, service_role;

-- Đối tượng do role postgres (SQL Editor) tạo SAU đây tự có quyền — y như public.
alter default privileges for role postgres in schema coinsort
  grant all on tables to postgres, anon, authenticated, service_role;
alter default privileges for role postgres in schema coinsort
  grant all on functions to postgres, anon, authenticated, service_role;
alter default privileges for role postgres in schema coinsort
  grant all on sequences to postgres, anon, authenticated, service_role;

-- Đối tượng đã tồn tại (khi chạy lại header trên schema cũ).
grant all on all tables in schema coinsort to postgres, anon, authenticated, service_role;
grant all on all sequences in schema coinsort to postgres, anon, authenticated, service_role;
grant all on all functions in schema coinsort to postgres, anon, authenticated, service_role;

-- Extension dùng chung (Supabase đặt ở schema extensions; if not exists = no-op).
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- (Tuỳ chọn, thay cho bước tay ở trên — chỉ dùng khi biết chắc danh sách schema
--  đang expose. Bỏ comment 2 dòng dưới nếu muốn:)
-- alter role authenticator set pgrst.db_schemas = 'public, graphql_public, coinsort';
-- notify pgrst, 'reload config';
