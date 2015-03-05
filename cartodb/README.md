# CartoDB examples

## Get unique list of receivers found in tracking data

```SQL
SELECT
    transmitter,
    count(*)
FROM "fish-tracking".fish_tracking_test
GROUP BY transmitter
ORDER BY count DESC
```

## Show tracking data for a single transmitter

```SQL
SELECT
    date_time,
    transmitter,
    r.the_geom,
    r.the_geom_webmercator
FROM "fish-tracking".fish_tracking_test t
LEFT JOIN lifewatch.fish_tracking_receivers r
ON t.receiver = r.receiver_id
WHERE transmitter = 'A69-1601-29929'
```

## Show catch locations

For this we need to populate `the_geom` and `the_geom_webmercator` with `catch_latitude` and `catch_longitude`.

```SQL
SELECT
	cartodb_id,
	transmitter_id,
	project,
	scientific_name,
	catched_at,
	catch_latitude,
	catch_longitude,
	catch_location,
	st_setsrid(st_point(catch_longitude, catch_latitude),4326) as the_geom,
	st_transform(st_setsrid(st_point(catch_longitude, catch_latitude),4326),3785) as the_geom_webmercator
FROM lifewatch.fish_tracking_transmitters
```

## Export receiver data with Lambert x y coordinates

In the table `fish_tracking_receivers` use:

```SQL
SELECT
    *,
    ST_X(ST_Transform(the_geom,31370)) as x,
    ST_Y(ST_Transform(the_geom,31370)) as y
FROM lifewatch.fish_tracking_receivers
ORDER BY cartodb_id
```

In the header, click `options > Export...` and choose a format.
