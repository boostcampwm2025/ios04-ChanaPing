declare
  v_place jsonb;
begin
  if new.place_id is not null then
    select jsonb_build_object(
      'place_id', p.place_id,
      'name', p.name,
      'latitude', st_y(p.location::geometry),
      'longitude', st_x(p.location::geometry)
    )
    into v_place
    from public.places p
    where p.place_id = new.place_id;
  else
    v_place := null;
  end if;

  perform realtime.send(
    jsonb_build_object(
      'type', 'created',
      'message', jsonb_build_object(
        'id', new.id,
        'author_id', new.author_id,
        'created_at', new.created_at,
        'content', new.content,
        'latitude', new.latitude,
        'longitude', new.longitude,
        'place', v_place
      )
    ),
    'messages:nearby',
    'messages-nearby',
    false
  );

  return new;
end;