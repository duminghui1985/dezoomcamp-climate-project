{{
  config(
    partition_by={
      "field": "record_year",
      "data_type": "int64",
      "range": {
        "start": 1960,
        "end": 2024,
        "interval": 1
      }
    },
    cluster_by=["country_code"]
  )
}}

with temperature_data as (
    select * from {{ ref('int_temperature_standardized') }}
),

population_data as (
    select * from {{ ref('stg_population') }}
)

select
    t.country_code,
    p.country,
    t.record_year,
    t.annual_avg_temp,
    p.population
from temperature_data t
inner join population_data p
    on t.country_code = p.country_code
    and t.record_year = p.record_year