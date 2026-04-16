{{
  config(
    cluster_by=["country"]
  )
}}

with base_data as (
    select 
        country,
        extract(year from record_date) as r_year,
        annual_avg_temp
    from {{ ref('fact_climate_population') }}
),

temp_start as (
    select 
        country, 
        annual_avg_temp as temp_start_year
    from base_data
    where r_year = {{ var('project_start_year') }}
),

temp_end as (
    select 
        country,
        annual_avg_temp as temp_end_year
    from base_data
    where r_year = {{ var('current_expected_end_year') }}
)

select
    e.country,
    s.temp_start_year,
    e.temp_end_year,
    round(e.temp_end_year - s.temp_start_year, 4) as total_increase
from temp_end e
inner join temp_start s on e.country = s.country