with year_stats as (
    select
        count(distinct extract(year from record_date)) as actual_year_count,
        min(extract(year from record_date)) as min_y,
        max(extract(year from record_date)) as max_y
    from {{ ref('fact_climate_population') }}
)

select *
from year_stats
where 
    -- no gap in years
    (max_y - min_y + 1) != actual_year_count