begin
  if old.deleted_at is null and new.deleted_at is not null then
    perform realtime.send(
      jsonb_build_object('type','deleted','id', new.id),
      'messages:nearby',
      'messages-nearby',
      false
    );
  end if;

  return new;
end;
