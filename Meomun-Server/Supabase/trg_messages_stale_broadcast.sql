begin
  if old.is_fresh = true and new.is_fresh = false then
    perform realtime.send(
      jsonb_build_object('type','stale','id', new.id),
      'messages:nearby',
      'messages-nearby',
      false
    );
  end if;

  return new;
end;
