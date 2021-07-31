--[Tabelas]--

CREATE TABLE HOSPEDE (
 codHospede SERIAL NOT NULL ,
 nome VARCHAR(50) ,
 cidade VARCHAR(50) ,
 dataNascimento DATE ,
PRIMARY KEY(codHospede));

CREATE TABLE ATENDENTE (
 codAtendente SERIAL NOT NULL ,
 codSuperior INTEGER NOT NULL ,
 nome VARCHAR(50) ,
PRIMARY KEY(codAtendente),
FOREIGN KEY(codSuperior) REFERENCES ATENDENTE(codAtendente));
 
CREATE INDEX IFK_Rel_01 ON ATENDENTE (codSuperior);

CREATE TABLE HOSPEDAGEM (
 codHospedagem SERIAL NOT NULL ,
 codAtendente INTEGER NOT NULL ,
 codHospede INTEGER NOT NULL ,
 dataEntrada DATE ,
 dataSaida DATE ,
 numQuarto INTEGER ,
 valorDiaria DECIMAL(9,2) ,
PRIMARY KEY(codHospedagem),
FOREIGN KEY(codHospede) REFERENCES HOSPEDE(codHospede),
FOREIGN KEY(codAtendente) REFERENCES ATENDENTE(codAtendente));
 
CREATE INDEX IFK_Rel_02 ON HOSPEDAGEM (codHospede);
CREATE INDEX IFK_Rel_03 ON HOSPEDAGEM (codAtendente);

--[Funcoes]--
-- Nomes
CREATE OR REPLACE FUNCTION _nomes() RETURNS VARCHAR(30) AS
$$
DECLARE
	cria_nome varchar(15);
	cria_sobrenome varchar(15);
	nomecomp varchar(30);
BEGIN
	CREATE TEMP TABLE tab_temp_nome(nome varchar(15), sobrenome varchar(15));
	INSERT INTO tab_temp_nome VALUES ('Mariana', 'Dreyer'), ('Diego','Skieresz'), ('Paulo', 'Breidenbach'),
	('Roger', 'Rodrigues'),('Fernanda', 'Ross'),('Mario', 'Bross'),('Bruce', 'Wayne'),
	('Fabio', 'Stark'),('James', 'Bond'),('Maria','Rambeau');
	cria_nome := (SELECT nome from tab_temp_nome ORDER BY RANDOM() LIMIT 1);
	cria_sobrenome := (SELECT sobrenome from tab_temp_nome ORDER BY RANDOM() LIMIT 1);
	nomecomp := cria_nome || ' ' || cria_sobrenome ;
	DROP TABLE tab_temp_nome;
RETURN nomecomp;
END;
$$ LANGUAGE 'plpgsql';

--cidade
CREATE OR REPLACE FUNCTION _cidades() RETURNS VARCHAR(30) AS
$$
DECLARE
	nome_cidade varchar(30);
BEGIN
	CREATE TEMP TABLE tab_temp_cidade(cidade varchar(15));
	INSERT INTO tab_temp_cidade VALUES ('Porto Alegre'), ('Canoas'), ('São Paulo'),
	('Rio de Janeiro'), ('Gramado'), ('Amapa'), ('Manaus');
	
	nome_cidade := (SELECT cidade from tab_temp_cidade ORDER BY RANDOM() LIMIT 1);
	
	DROP TABLE tab_temp_cidade;
RETURN nome_cidade;
END;
$$ LANGUAGE 'plpgsql';

--data nascimento	
CREATE OR REPLACE FUNCTION dataNascimento(idade int) RETURNS DATE AS
$$
DECLARE
	aniversario date;
BEGIN
	aniversario:= '1/1/1980'::date + ('1 day'::interval*floor(random()*14610));

RETURN aniversario;
END;
$$ LANGUAGE 'plpgsql';

--data estadia
CREATE OR REPLACE FUNCTION dataEstadia(date,date) RETURNS DATE
LANGUAGE SQL
AS $$
    SELECT $1 + floor( ($2 - $1 + 1) * random() )::integer;
$$;

--[INSERTS]--
--a) Escrever um procedimento para inserir registros na tabela de HÓSPEDES.
CREATE OR REPLACE FUNCTION insHosp(qtdadeHospede int) RETURNS VOID AS
$$
DECLARE
	Hospidade int;
	Hospnome varchar(50);
	Hospcidade varchar(50);
	Hospnascimento date;
BEGIN
	FOR i IN 1..qtdadeHospede LOOP
	Hospidade := (SELECT 10 + round(CAST (random()*(1+65-18) AS NUMERIC),0));
	Hospnome := (SELECT _nomes());
	Hospcidade :=(SELECT _cidades());
	Hospnascimento := (SELECT dataNascimento(hospidade));
	INSERT INTO HOSPEDE(nome,cidade,dataNascimento) VALUES (Hospnome,Hospcidade,Hospnascimento);
	i = i+1;
	END lOOP;
RETURN;
END;
$$ language 'plpgsql';

--b) Escrever procedimento para inserir registros na tabela ATENDENTE
-- Receber por parâmetro a quantidade de atendentes que deverão ser gerados 
-- Fixar que o atendente 1 é superior de todos os demais
CREATE OR REPLACE FUNCTION insAtend(qtdAtend int) RETURNS VOID AS
$$
DECLARE
	at_Nome varchar(50);
	at_Codigo integer;
BEGIN
	FOR i IN 1..qtdAtend LOOP
	at_Codigo := i;
	at_Nome := (SELECT _nomes());
	INSERT INTO ATENDENTE(codAtendente,codSuperior,nome) VALUES (at_Codigo,01,at_Nome);
	i = i+1;
	END LOOP;
RETURN;
END;
$$ language 'plpgsql';

--c) Escrever procedimento para inserir registros na tabela HOSPEDAGEM:
-- Receber por parâmetro a quantidade de hospedagens que deverão ser geradas e o 
--intervalo de tempo para o qual serão geradas as diárias (duas datas);
-- As hospedagens serão aleatoriamente vinculadas a hóspedes e atendentes
-- A data de entrada da hospedagem deverá ser gerada de forma que esteja dentro do 
--intervalo passado por parâmetro
-- O sistema deverá considerar que as datas de saída de algumas hospedagens deverão 
--ser preenchidas (vamos imaginar que o hotel tem um número de quartos que vai do 1 ao 100. Logo, somente uma hospedagem poderá estar aberta para esses quartos ao mesmo tempo – sempre a mais recente).
--Para facilitar imagine que a estadia de uma pessoa não ultrapassa 3 dias.
CREATE OR REPLACE FUNCTION inserirHospedagem(qtdHospedagens int,dt1 date, dt2 date) RETURNS VOID AS
$$
DECLARE
	Vhospede int;
	Vatendente int;
	dtInicio date;
	dtFim date;
	nQuarto int;
	vdiaria decimal(9,2);
BEGIN
	vdiaria := 110;
	for i in 1..qtdHospedagens LOOP
	Vhospede := (SELECT codHospede FROM hospede ORDER BY RANDOM() LIMIT 1);
	Vatendente := (SELECT codAtendente FROM atendente ORDER BY RANDOM() LIMIT 1);
	dtInicio := (SELECT(dataEstadia(dt1,dt2)));
	dtFim := (SELECT dtInicio + round(random()*3)::int * '1 day'::interval AS data);
	nQuarto := (SELECT FLOOR(random() * 50 + 1)::int);
		PERFORM * FROM HOSPEDAGEM WHERE numQuarto = nQuarto and dtInicio between dataEntrada and dataSaida;
		IF FOUND THEN
			RAISE EXCEPTION 'Quarto reservado.';
		ELSE
			INSERT INTO hospedagem(codAtendente,codHospede,dataEntrada,dataSaida,numQuarto,valordiaria) 
			VALUES (Vatendente, Vhospede,dtInicio,dtFim,nQuarto,vdiaria);
			i = i+1;
		END IF;
	END LOOP;
RETURN;
END;
$$ language 'plpgsql';

--d) Escreva um procedimento para atualizar dados na tabela de hospedagem da seguinte forma:
-- Receber por parâmetro o código da hospedagem e os valores a serem alterados
-- Somente devem ser atualizados os campos datasaida, codatendente e valorDiaria
-- Nem todos os campos serão atualizados ao mesmo tempo, ou seja, haverá situações em
--que apenas um, dois ou os três serão atualizados - Utilizar um único UPDATE de forma dinãmica
-- Ao final retornar a quantidade de linhas atualizadas

CREATE OR REPLACE FUNCTION atualHospedagem(codH int,dtS date,codAt integer, diaria decimal(9,2)) RETURNS integer AS
$$
DECLARE
	linhas integer := 0;
BEGIN
	PERFORM * FROM HOSPEDAGEM WHERE dtS < dataEntrada and codHospedagem = codH;
		IF FOUND THEN
			RAISE EXCEPTION 'ERRO! A data de saida anterior a data de entrada.';
		END IF;
	UPDATE  HOSPEDAGEM SET 
	dataSaida = (dtS),
	codAtendente =(codAt),
	valorDiaria = (diaria)
	WHERE codHospedagem = codH;	
	GET DIAGNOSTICS linhas = ROW_COUNT;	
RETURN linhas;
END;
$$ LANGUAGE PLPGSQL;


----------[Consulta tabelas]----------

SELECT * FROM hospede;
SELECT * FROM atendente;
SELECT * FROM hospedagem 

----------[Chamada de Insert]----------

SELECT insHosp(10)
SELECT insAtend(5)
SELECT inserirHospedagem(100,'2010-01-01', '2011-12-31')
SELECT atualHospedagem(223,'2016-02-20',2, 100)
SELECT atualHospedagem(14,'2020-04-04',4, 120)
SELECT atualHospedagem(13,'2020-03-30',1, 70)
SELECT atualHospedagem(5,'2020-03-28',1, 100)

------------[Consulta 1]------------
SELECT 
	hospede.nome AS hospede, 
	atendente.nome AS atendente, 
	extract(year from age(hospedagem.dataentrada, hospede.datanascimento)):: int AS idade, 
	hospedagem.numQuarto, 
	(datasaida - dataentrada) * valordiaria AS total 
FROM 
	hospede, atendente, hospedagem
WHERE 
	hospedagem.codAtendente = atendente.codAtendente 
	AND hospedagem.codHospede = hospede.codHospede	
	AND hospedagem.datasaida IS NOT NULL
	AND extract(year from age(hospedagem.dataentrada, hospede.datanascimento)):: int = 21
	AND EXISTS (SELECT 1 FROM Hospedagem HG, hospede H
	where hospedagem.codHospede = hospede.codHospede
	and extract(year from age(hospedagem.dataentrada, hospede.datanascimento)) between 40 and 45
	AND hospedagem.dataEntrada >= HG.dataEntrada 
	AND hospedagem.dataEntrada <= HG.dataSaida)
	
ORDER BY 
	1  ASC, 5 DESC
LIMIT 10;

------------[Consulta 2]------------

SELECT
		SUM((datasaida - dataentrada) * valordiaria) AS total, 
		to_char(hospedagem.datasaida, 'YYYY-MM') as DATA,
		upper(atendente.nome) as Atendente 
		
FROM 
	atendente, hospedagem
	where atendente.codatendente = hospedagem.codatendente
	and hospedagem.datasaida NOT BETWEEN '2011-06-01' and '2011-07-30'
	and atendente.codatendente = atendente.codsuperior
	and ((datasaida - dataentrada) * valordiaria)  >= 
	(select AVG ((datasaida - dataentrada) * valordiaria) 
	from hospedagem where hospedagem.datasaida > 
	(select max (hospedagem.datasaida)-10 from hospedagem))

GROUP BY 
	atendente.codatendente, hospedagem.datasaida
ORDER BY 
     to_char(hospedagem.datasaida, 'YYYY-MM') asc;
	
	
------------[Consulta 3]------------
INSERT INTO HOSPEDE VALUES (15,'FABIO','MANAUS','1983-07-07')
SELECT 
	hospede.nome, 
	(dataSaida - dataEntrada) * valordiaria AS total,
		(CASE 
			WHEN ((datasaida - dataentrada) * valordiaria)  between 0 and 1000 THEN 'E'  
			WHEN ((datasaida - dataentrada) * valordiaria)  between 1000.01 and 3000.0 THEN 'D'  
			WHEN ((datasaida - dataentrada) * valordiaria)  between 3000.01 and 7000.0 THEN 'C'
			WHEN ((datasaida - dataentrada) * valordiaria)  between 7001.0 and 10000.0 THEN 'B'  
			ELSE '10' 
		END) AS Classe
FROM 
	hospede, hospedagem
WHERE 
	hospede.codhospede = hospedagem.codhospede
AND
	hospedagem.datasaida BETWEEN '2010-01-01' AND '2010-12-31'
AND 
	hospede.cidade  ~>=~ 'A' AND hospede.cidade ~<=~ 'M'
AND
	UPPER (hospede.nome) in ('FABIO') 
AND 
	hospedagem.datasaida >= (select max (hospedagem.datasaida)-30 from hospedagem) 
ORDER BY 
	hospede.nome, Classe
	 
------------[Consulta 4]------------
SELECT
	TB.cidade,
	TB.Soma_das_diarias
FROM ( 
SELECT
	hospede.cidade,
	SUM ((dataSaida - dataEntrada) * valordiaria) AS Soma_das_diarias
FROM
	hospede, hospedagem
	WHERE hospede.codhospede = hospedagem.codhospede
GROUP BY
	hospede.cidade
LIMIT 3) TB, 
 ( 
SELECT
	hospede.cidade,
	SUM ((dataSaida - dataEntrada) * valordiaria) AS Soma_das_diarias
FROM
	hospede, hospedagem
	WHERE hospede.codhospede = hospedagem.codhospede
GROUP BY
	hospede.cidade ) TB2 
WHERE TB2.Soma_das_diarias = TB.Soma_das_diarias
ORDER BY  Soma_das_diarias DESC LIMIT 4
;
------------[Consulta 5]------------
SELECT
	(
        SELECT  atendente.nome
        FROM    atendente
        WHERE   atendente.codatendente = 1
	) As Superior,
	atendente.nome, COUNT( hospedagem.codhospedagem )AS Qnt_Atendimento
FROM
	atendente LEFT JOIN hospedagem ON atendente.codatendente = hospedagem.codatendente
AND	
	hospedagem.datasaida >= (select max (hospedagem.datasaida)-30 from hospedagem) 
GROUP BY
	atendente.nome, atendente.codatendente;





--delete from hospedagem 
--Delete from atendente
--delete from hospede

