CREATE TABLE daymet_annual_prcp AS (
  SELECT featureid, avg(prcp) as prcp
  FROM daymet
  GROUP BY featureid
)