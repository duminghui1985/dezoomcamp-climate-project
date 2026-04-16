{% set start_year = var('project_start_year') %}

{{
  config(
    partition_by={
      "field": "record_date",
      "data_type": "date",
      "granularity": "year"
    },
    cluster_by=["country"]
  )
}}

with temperature as (
    select * from {{ ref('int_temperature_standardized') }}
    where record_year >= {{ start_year }}
),

population as (
    select * from {{ ref('stg_population') }}
    where record_year >= {{ start_year }}
)

select
    t.country_code,
    p.country,
    date(t.record_year, 1, 1) as record_date, 
    t.annual_avg_temp,
    p.population
from temperature t
inner join population p
    on t.country_code = p.country_code
    and t.record_year = p.record_year