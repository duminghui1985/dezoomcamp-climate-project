{{ config(materialized='view') }}

with temp_raw as (
    select
        parse_date('%Y-%m-%d', dt) as event_date,
        cast(AverageTemperature as float64) as avg_temp,
        country
    from {{ source('raw_climate_source', 'ext_temperature') }}
    where AverageTemperature is not null
)

select
    country,
    extract(year from event_date) as record_year,
    avg(avg_temp) as annual_avg_temp
from temp_raw
group by 1, 2