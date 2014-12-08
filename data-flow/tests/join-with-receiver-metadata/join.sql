SELECT
    d.cartodb_id,
    d.receiver_id,
    d.date_time,
    r.cartodb_id as cartodb_id_metadata,
    r.receiver_id as receiver_id_metadata,
    r.deployed_at,
    r.removed_at
FROM
    data as d
LEFT JOIN
    receiver_metadata as r
ON
    d.receiver_id = r.receiver_id
    AND d.date_time >= coalesce(r.deployed_at,'2012-01-01')
    AND d.date_time <= coalesce(r.removed_at,current_date)
ORDER BY
    d.date_time,
    d.cartodb_id
