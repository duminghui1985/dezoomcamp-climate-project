with temperature as (
    select * from {{ ref('stg_temperature') }}
),
mapping as (
    select * from {{ ref('country_mapping') }}
)
select
    m.country_code,
    t.record_year,
    t.annual_avg_temp
from temperature t
inner join mapping m 
    on t.country = m.temp_name