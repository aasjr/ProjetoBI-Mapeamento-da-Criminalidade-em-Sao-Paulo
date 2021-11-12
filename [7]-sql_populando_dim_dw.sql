-- 4 - Apos a carga da st.st_crime_sp via PDI , temos a carga das diferentes categorias nas dimensões:

-- 4.1 - Populando dw.dim_crime :

INSERT INTO dw.dim_crime(nm_crime,nm_conduta)
SELECT DISTINCT nm_crime,nm_conduta
FROM st.st_crime_sp;

-- 4.2 - Populando dw.dim_delegacia :

INSERT INTO dw.dim_delegacia(nr_delegacia,nm_delegacia,nm_departamento)
SELECT DISTINCT nr_delegacia,nm_delegacia,nm_departamento
FROM st.st_crime_sp;

-- 4.3 - Populando dw.dim_local :

INSERT INTO dw.dim_local(nr_latitude,nr_longitude,nm_cidade,nm_logradouro,nm_tipo_local)
SELECT DISTINCT nr_latitude,nr_longitude,nm_cidade,nm_logradouro,nm_tipo_local
FROM st.st_crime_sp;

-- 4.4 - Populando dw.dim_vitima :

INSERT INTO dw.dim_vitima(nm_tipo_vitima,nm_sexo_vitima,nr_idade_vitima)
SELECT DISTINCT nm_tipo_vitima,nm_sexo_vitima,nr_idade_vitima
FROM st.st_crime_sp;
