create or replace function public.get_nearby_messages(
  p_lat double precision,
  p_lon double precision,
  p_limit integer default null
)
returns jsonb
language sql
stable
as $$
    with center as (
        select st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography as g
    ),
    filtered as (
        select
        m.id,
        m.author_id,
        m.created_at,
        m.content,
        m.latitude,
        m.longitude,
        m.place_id,
        st_distance(m.location, (select g from center)) as dist_m
        from public.messages m
        where m.location is not null
        and m.deleted_at is null
        and (m.expires_at is null or m.expires_at > now())
        and st_dwithin(m.location, (select g from center), 1200)
        order by dist_m asc
        limit coalesce(p_limit, 1000000)
    )
    select coalesce(
        jsonb_agg(
        jsonb_build_object(
            'id', f.id,
            'author_id', f.author_id,
            'created_at', f.created_at,
            'content', f.content,
            'latitude', f.latitude,
            'longitude', f.longitude,
            'place',
            case
                when f.place_id is null then null
                else jsonb_build_object(
                'place_id', p.place_id,
                'name', p.name,
                'latitude', p.latitude,
                'longitude', p.longitude
                )
            end
        )
        ),
        '[]'::jsonb
    )
    from filtered f
    left join public.places p on p.place_id = f.place_id;
$$;