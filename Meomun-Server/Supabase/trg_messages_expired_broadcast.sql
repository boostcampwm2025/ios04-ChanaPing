begin
  if old.expired_at is null and new.expired_at is not null then
    perform realtime.send(
      jsonb_build_object('type','expired','id', new.id),
      'messages:nearby',
      'messages-nearby',
      false
    );
  end if;

  return new;
end;
