create or replace table test AS (
    select
        x::TINYINT as x,
        (x+2)::TINYINT as y,
        uuid()::VARCHAR as customer_id,
        uuid()::VARCHAR as customer_varchar_field,
        '2024-02-01'::TIMESTAMP + interval 1 minute * (random() * 20000)::int as customer_timestamp,
        (random() > 0.5)::BOOL as customer_flag,
        (random()*10)::INTEGER as customer_integer_field,
        CAST(1e12 * random() AS FLOAT) as customer_float_field,
        CAST(1e12 * random() AS DOUBLE) as customer_double_field,
        (random()*10)::BIGINT as customer_bigint_field,
        10101::BIT as customer_bit_field,
        '\xAA\xAB\xAC'::BLOB as customer_blob_field,
        '2024-03-14'::DATE as customer_date_field,
        (x * 3.141592653589793238462643)::DECIMAL(27, 24) as customer_decimal_field,
        (x * 10e10)::HUGEINT as customer_hugeint_field,
        (x - 1)::REAL as customer_real_field,
        (x * 3000)::SMALLINT as customer_small_int_field,
        -- DOES NOT WORK x * (INTERVAL 5 HOUR) as customer_interval_field,
        -- DOES NOT WORK TIME '01:02:03' as customer_time_field,
        -- DOES NOT WORK '2024-03-14 15:14:15 Europe/Amsterdam'::TIMESTAMPTZ as customer_timestamptz_field,

    from generate_series(1, 10) g(x)
);