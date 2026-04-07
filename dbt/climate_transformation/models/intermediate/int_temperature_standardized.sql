with temperature as (
    select * from {{ ref('stg_temperature') }}
),

mapping as (
    select * from {{ ref('country_mapping') }}
),

joined_data as (
    select
        m.country_code,
        t.record_year,
        t.annual_avg_temp
    from temperature t
    inner join mapping m 
        on t.country = m.temp_name
)

-- deduplication
select
    country_code,
    record_year,
    -- if multiple original names (like Denmark and Denmark (Europe)) point to the same code,
    -- we take their average as the temperature for that country and year
    avg(annual_avg_temp) as annual_avg_temp
from joined_data
group by 1, 2