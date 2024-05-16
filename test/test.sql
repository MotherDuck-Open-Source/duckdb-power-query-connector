create or replace table test AS (
    select
        (random() > 0.5)::BOOL as customer_flag,
        x::TINYINT as x,
        (random() * 10)::SMALLINT as customer_small_int_field,
        (random() * 10)::INTEGER as customer_integer_field,
        (random() * 10)::BIGINT as customer_bigint_field,
        '2024-03-14'::DATE as customer_date_field,
        TIME '01:02:03' as customer_time_field,
        '2024-02-01'::TIMESTAMP + interval 1 minute * (random() * 20000)::int as customer_timestamp,
        (x * 3.141592653589793238462643)::DECIMAL(27, 24) as customer_decimal_field,
        (1e12 * random())::REAL as customer_real_field,
        (1e12 * random())::DOUBLE as customer_double_field,
        uuid()::VARCHAR as customer_varchar_field,
        '\xAA\xAB\xAC'::BLOB as customer_blob_field,
        x * (INTERVAL 5 HOUR) as customer_interval_field,
        (x * 20)::UTINYINT as customer_utinyint_field,
        (x * 6000)::USMALLINT as customer_usmallint_field,
        (random() * 10e8)::UINTEGER as customer_uinteger_field,
        (x * 10e15)::UBIGINT as customer_bigint_field,
        '2024-03-14 15:14:15'::TIMESTAMPTZ as customer_timestamptz_field,
        10101::BIT as customer_bit_field,
        (x * 10e15)::UHUGEINT as customer_uhugeint_field,
        (x * 10e10)::HUGEINT as customer_hugeint_field,
        gen_random_uuid() as customer_uuid_field,

    from generate_series(1, 10) g(x)
);
