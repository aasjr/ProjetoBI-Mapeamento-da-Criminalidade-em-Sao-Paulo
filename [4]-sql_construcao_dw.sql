-- 1 - Criação dos schemas 

-- 1.1 - Criação do schema "stage" :
CREATE SCHEMA st;

-- 1.2 - Criação do schema "dw" :
CREATE SCHEMA dw;

-- 2 - Criação da tabela "st_crime_sp" :


CREATE SEQUENCE st.st_crime_sp_pk_crime_seq;

CREATE TABLE st.st_crime_sp (
                pk_crime INTEGER NOT NULL DEFAULT nextval('st.st_crime_sp_pk_crime_seq'),
                nm_crime VARCHAR(70),
                nm_conduta VARCHAR(30),
                dt_crime DATE NOT NULL,
                nr_delegacia INTEGER,
                nm_delegacia VARCHAR(100),
                nm_departamento VARCHAR(100),
                nm_tipo_vitima VARCHAR(50),
                nm_sexo_vitima CHAR,
                nr_idade_vitima INTEGER,
                nr_latitude FLOAT,
                nr_longitude FLOAT,
                nm_cidade VARCHAR(40),
                nm_logradouro VARCHAR(80),
                nm_tipo_local VARCHAR(80),
                CONSTRAINT pk_crime PRIMARY KEY (pk_crime)
);


ALTER SEQUENCE st.st_crime_sp_pk_crime_seq OWNED BY st.st_crime_sp.pk_crime;


-- 3 - Criação das tabelas dimensões e fato do DW :

-- 3.1 - Dimensão tempo "dim_tempo" --Scrip cedido pelo Prof. Anderson:

---script dim_tempo versão:20201217
---prof. anderson nascimento
create table dw.dim_tempo (
sk_tempo integer not null,
nk_tempo date not null,
desc_data_completa varchar(60) not null,
nr_ano integer not null,
nm_trimestre varchar(20) not null,
nr_ano_trimestre varchar(20) not null,
nr_mes integer not null,
nm_mes varchar(20) not null,
ano_mes varchar(20) not null,
nr_semana integer not null,
ano_semana varchar(20) not null,
nr_dia integer not null,
nr_dia_ano integer not null,
nm_dia_semana varchar(20) not null,
flag_final_semana char(3) not null,
flag_feriado char(3) not null,
nm_feriado varchar(60) not null,
dt_final timestamp not null,
dt_carga timestamp not null,
constraint sk_tempo_pk primary key (sk_tempo)
);

insert into dw.dim_tempo
select to_number(to_char(datum,'yyyymmdd'), '99999999') as sk_tempo,
datum as nk_tempo,
to_char(datum,'dd/mm/yyyy') as data_completa_formatada,
extract (year from datum) as nr_ano,
'T' || to_char(datum, 'q') as nm_trimestre,
to_char(datum, '"T"q/yyyy') as nr_ano_trimenstre,
extract(month from datum) as nr_mes,
to_char(datum, 'tmMonth') as nm_mes,
to_char(datum, 'yyyy/mm') as nr_ano_nr_mes,
extract(week from datum) as nr_semana,
to_char(datum, 'iyyy/iw') as nr_ano_nr_semana,
extract(day from datum) as nr_dia,
extract(doy from datum) as nr_dia_ano,
to_char(datum, 'tmDay') as nm_dia_semana,
case when extract(isodow from datum) in (6, 7) then 'Sim' else 'Não'
end as flag_final_semana,
case when to_char(datum, 'mmdd') in ('0101','0421','0501','0907','1012','1102','1115','1120','1225') then 'Sim' else 'Não'
end as flag_feriado,
case 
---incluir aqui os feriados
when to_char(datum, 'mmdd') = '0101' then 'Ano Novo' 
when to_char(datum, 'mmdd') = '0421' then 'Tiradentes'
when to_char(datum, 'mmdd') = '0501' then 'Dia do Trabalhador'
when to_char(datum, 'mmdd') = '0907' then 'Dia da Pátria' 
when to_char(datum, 'mmdd') = '1012' then 'Nossa Senhora Aparecida' 
when to_char(datum, 'mmdd') = '1102' then 'Finados' 
when to_char(datum, 'mmdd') = '1115' then 'Proclamação da República'
when to_char(datum, 'mmdd') = '1120' then 'Dia da Consciência Negra'
when to_char(datum, 'mmdd') = '1225' then 'Natal' 
else 'Não é Feriado'

end as nm_feriado,
'2199-12-31',
current_date as data_carga
from (
---incluir aqui a data de início do script, criaremos 15 anos de datas
select '2009-01-01'::date + sequence.day as datum
from generate_series(0,5479) as sequence(day)
group by sequence.day
) dq
order by 1;

-- fim da "dim_tempo"

-- 3.2 - Criação da dimensões "dim_crime","dim_delegacia","dim_vitima","dim_local" e da Fato "ft_ocorrencia" : 

CREATE SEQUENCE dw.dim_crime_sk_crime_seq;

CREATE TABLE dw.dim_crime (
                sk_crime INTEGER NOT NULL DEFAULT nextval('dw.dim_crime_sk_crime_seq'),
                nm_crime VARCHAR(70) NOT NULL,
                nm_conduta VARCHAR(30) NOT NULL,
                CONSTRAINT dim_crime_pk PRIMARY KEY (sk_crime)
);


ALTER SEQUENCE dw.dim_crime_sk_crime_seq OWNED BY dw.dim_crime.sk_crime;

CREATE SEQUENCE dw.dim_local_sk_local_seq;

CREATE TABLE dw.dim_local (
                sk_local INTEGER NOT NULL DEFAULT nextval('dw.dim_local_sk_local_seq'),
                nr_latitude FLOAT NOT NULL,
                nr_longitude FLOAT NOT NULL,
                nm_cidade VARCHAR(40) NOT NULL,
                nm_logradouro VARCHAR(80), NOT NULL,
                nm_tipo_local VARCHAR(80) NOT NULL,
                CONSTRAINT dim_local_pk PRIMARY KEY (sk_local)
);


ALTER SEQUENCE dw.dim_local_sk_local_seq OWNED BY dw.dim_local.sk_local;

CREATE SEQUENCE dw.dim_vitima_sk_vitima_seq;

CREATE TABLE dw.dim_vitima (
                sk_vitima INTEGER NOT NULL DEFAULT nextval('dw.dim_vitima_sk_vitima_seq'),
                nm_tipo_vitima VARCHAR(20) NOT NULL,
                nm_sexo_vitima CHAR(1) NOT NULL,
                nr_idade_vitima INTEGER NOT NULL,
                CONSTRAINT dim_vitima_pk PRIMARY KEY (sk_vitima)
);


ALTER SEQUENCE dw.dim_vitima_sk_vitima_seq OWNED BY dw.dim_vitima.sk_vitima;

CREATE SEQUENCE dw.dim_delegacia_sk_delegacia_seq;

CREATE TABLE dw.dim_delegacia (
                sk_delegacia INTEGER NOT NULL DEFAULT nextval('dw.dim_delegacia_sk_delegacia_seq'),
                nr_delegacia INTEGER NOT NULL,
                nm_delegacia VARCHAR(30) NOT NULL,
                nm_departamento VARCHAR(40) NOT NULL,
                CONSTRAINT dim_delegacia_pk PRIMARY KEY (sk_delegacia)
);


ALTER SEQUENCE dw.dim_delegacia_sk_delegacia_seq OWNED BY dw.dim_delegacia.sk_delegacia;

CREATE TABLE dw.ft_ocorrencia (
                sk_vitima INTEGER NOT NULL,
                sk_delegacia INTEGER NOT NULL,
                sk_crime INTEGER NOT NULL,
                sk_local INTEGER NOT NULL,
                sk_tempo INTEGER NOT NULL
);


ALTER TABLE dw.ft_ocorrencia ADD CONSTRAINT dim_tempo_ft_ocorrencia_fk
FOREIGN KEY (sk_tempo)
REFERENCES dw.dim_tempo (sk_tempo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE dw.ft_ocorrencia ADD CONSTRAINT dim_crime_ft_ocorrencia_fk
FOREIGN KEY (sk_crime)
REFERENCES dw.dim_crime (sk_crime)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE dw.ft_ocorrencia ADD CONSTRAINT dim_local_ft_ocorrencia_fk
FOREIGN KEY (sk_local)
REFERENCES dw.dim_local (sk_local)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE dw.ft_ocorrencia ADD CONSTRAINT dim_vitima_ft_ocorrencia_fk
FOREIGN KEY (sk_vitima)
REFERENCES dw.dim_vitima (sk_vitima)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE dw.ft_ocorrencia ADD CONSTRAINT dim_delegacia_ft_ocorrencia_fk
FOREIGN KEY (sk_delegacia)
REFERENCES dw.dim_delegacia (sk_delegacia)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;