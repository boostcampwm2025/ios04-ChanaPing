begin
  update public.messages
  set is_fresh = false
  where is_fresh = true
    and created_at <= now() - interval '20 minutes'
    and deleted_at is null
    and expired_at is null;
end;
