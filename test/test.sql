create or replace table numbers as select x::TINYINT as x, (x+2)::TINYINT as y from generate_series(1,10) g(x);