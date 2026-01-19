create or replace function public.get_place_messages(
  p_place_id text,
  p_limit integer default null
)
returns table (
  id uuid,
  author_id uuid,
  created_at timestamptz,
  content text,
  latitude double precision,
  longitude double precision,
  expires_at timestamptz,
  deleted_at timestamptz,
  place_id text,
  place jsonb
)
language sql
stable
as $$
  select
    m.id,
    m.author_id,
    m.created_at,
    m.content,
    m.latitude,
    m.longitude,
    m.expires_at,
    m.deleted_at,
    m.place_id,
    (
      case
        when p.place_id is null then null
        else jsonb_build_object(
          'place_id', p.place_id,
          'name', p.name,
          'latitude', p.latitude,
          'longitude', p.longitude,
          'created_at', p.created_at
        )
      end
    )::jsonb as place
  from public.messages m
  left join public.places p
    on m.place_id = p.place_id
  where m.place_id = p_place_id
    and m.deleted_at is null
    and m.expires_at > now()
  order by m.created_at desc
  limit coalesce(p_limit, 100);
$$;
