# CartoDB documentation

## Export receiver data with Lambert x y coordinates

1. Go to the table `fish_tracking_receivers`
2. Use the following query:

    ```SQL
    SELECT
        *,
        ST_X(ST_Transform(the_geom,31370)) as x,
        ST_Y(ST_Transform(the_geom,31370)) as y
    FROM fish_tracking_receivers
    ORDER BY cartodb_id
    ```

3. In the header, click `options > Export...` and choose a format.
