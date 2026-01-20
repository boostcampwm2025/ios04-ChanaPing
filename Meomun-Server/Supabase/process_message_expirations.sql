begin
  update public.messages
  set expired_at = now()
  where expired_at is null
    and expires_at <= now()
    and deleted_at is null;
end;
