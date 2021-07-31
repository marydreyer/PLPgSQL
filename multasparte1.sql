create table ex_motorista
(cnh char(5) primary key,
nome varchar(20) not null,
totalMultas decimal(9,2) );

create table ex_multa
(id serial primary key,
cnh char(5) references ex_motorista(cnh) not null,
velocidadeApurada decimal(5,2) not null,
velocidadeCalculada decimal(5,2),
pontos integer not null,
valor decimal(9,2) not null);

insert into ex_motorista values ('123AB', 'Carlo');
insert into ex_motorista values ('321AB', 'João');

select * from fn_GeraMultas_Exemplo('123AB', 100)

-- select * from delete from ex_multa ---limpar a tabela


create or replace function fn_GeraMultas_Exemplo(pCNH char(5), pVelApurada DECIMAL(5,2))
returns varchar(50) as 
$$ 
DECLARE

_VelCalculada		integer		:=0;
_msg				varchar(80) := 'Sem Multa !!!!';
_aplicaMulta		char(01) 	:= 'N';
_pontoi				ex_multa.pontos%type;
_valori				decimal(5,2);
_nome				varchar(20);
_total				integer :=0;

begin 
--testar se o motorista existe mediante CNH enviado como parametro, buscando seu nome
perform * from ex_motorista where CNH = pCNH;
if not found then
	raise exception 'ERRO ao procurar tabela ex_multa';
else 
	select nome into _nome from ex_motorista where CNH = pCNH;
end if;

--primeiro, o calculo da velocidade
_VelCalculada := pVelApurada * 0.90;
--segundo, teste os itervalos p/ ver se o motorista tem multa e se tiver insere na tabela multa
-- –Se a velocidade calculada estiver entre 80.01 e 110 então o motorista deve ser multado em 120,00 e receber 20 pontos
-- –Se a velocidade calculada estiver entre 110.01 e 140 então o motorista deve ser multado em 350 e receber 40 pontos
-- –Se a velocidade calculada estiver acima de 140 então o motorista deve ser multado em 680 e receber 60 pontos
if (_VelCalculada >= 80.01 and _VelCalculada <= 110) then
	--aplica multa
	_aplicaMulta:= 'S';
	_valori		:=120;
	_pontoi		:=20;
elsif
	(_VelCalculada >= 110.01 and _VelCalculada <= 140) then
	--aplica multa
	_aplicaMulta:= 'S';
	_valori		:=350;
	_pontoi		:=40;
elsif
	(_VelCalculada > 140) then
	--aplica multa
	_aplicaMulta:= 'S';
	_valori		:=680;
	_pontoi		:=60;
end if;

if (_aplicaMulta= 'S') then
	insert into ex_multa (cnh,velocidadeApurada,velocidadeCalculada,pontos,valor)
	values (pCNH, pVelApurada, _VelCalculada, _pontoi, _valori );

	--Quarta etapa, somar o total de pontos do motorista---- 
	select sum(pontos) into _total from ex_multa where pCNH = CNH;	
	_msg := 'O motorista '|| _nome ||' soma '|| _total ||' pontos em multas !'; 
end if;
return _msg;
end;

$$ language 'plpgsql';

--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=

-- Exercício 02: Escreva um outro procedimento que atualize o campo totalMultas
-- da tabela ex_motorista a partir dos totais apurados para cada motorista apurado 
-- na tabela ex_multa.

-- •OBS1: motorista sem multa deverão possuir valor 0.00 no campo total multa;

-- •OBS2:cuidado para não duplicar valores na coluna totalMultas para os casos em 
-- que a rotina for disparada mais de uma vez.

insert into ex_motorista (cnh, nome) values ('123AC', 'Joao')

select * from ex_motorista
select * from ex_multa

create or replace function fn_AtualizaMultas_Exemplo(pCNH char(5))
returns varchar(50) as
$$ declare
-- Coloque aqui as variáveis
_TotalValor		decimal(15,2) := 0.0;
_nome           varchar(20);
_msg			varchar(80) := 'Motorista sem multas. ';
begin 
perform * from ex_multa where CNH = pCNH;
if not found then
     raise exception  'O MOTORISTA NÃO POSSUI MULTAS.';
else
    select nome into _nome from ex_motorista where CNH = pCNH;
end if;
	
select sum(valor) into _TotalValor from ex_multa where cnh = pCNH;
update ex_motorista set totalmultas = (select sum(valor) from ex_multa where cnh = pCNH);
_msg	:= 'O motorista '|| _nome ||'  possui ' || _TotalValor ||' em multas já somadas !!!';
return _msg;
end;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION FN_TEXTO_VALOR_MULTA (_VALOR DECIMAL(8,2)) RETURNS VARCHAR(30) AS
$$
DECLARE
_MSG VARCHAR(30);
BEGIN
_MSG := 'DEVE 1000 EM MULTAS';
IF _VALOR < 1000.00 THEN
_MSG := 'MENOS DE 1000 EM MULTAS';
ELSIF _VALOR > 1000.00 THEN
_MSG := 'MAIS DE 1000 EM MULTAS';
ELSIF _VALOR IS NULL THEN
_MSG:= 'SEM MULTAS';
END IF;
-- SOMENTE A PARTIR DA VERSÃO 8.4
/*CASE
WHEN (_VALOR < 1000) THEN _MSG := 'MENOS DE 1000 EM MULTAS‘;
WHEN (_VALOR > 1000.00) THEN _MSG := 'MAIS DE 1000 EM MULTAS‘;
WHEN (_VALOR IS NULL) THEN _MSG := 'SEM MULTAS‘;
END CASE;*/
RETURN _MSG;
END;
$$ LANGUAGE PLPGSQL;

SELECT
NOME
, FN_TEXTO_VALOR_MULTA(TOTALMULTAS)
, TOTALMULTAS
FROM EX_MOTORISTA;

--Monte um procedimento o qual possa gerenciar as mensagens de erro fm_msg() o qual receba um
--tipo de erro e gere uma respectiva mensagem;
CREATE OR REPLACE FUNCTION fm_msg(_CNH char(5)) RETURNS VOID AS $$
<<BLOCO_A>>
DECLARE
_MULTA RECORD;
_MOTORISTA RECORD;
BEGIN
SELECT * INTO _MOTORISTA FROM EX_MOTORISTA WHERE cnh = _CNH;
BEGIN
SELECT * into STRICT _MULTA FROM EX_MULTA WHERE CNH = _CNH;
EXCEPTION
WHEN NO_DATA_FOUND THEN
RAISE NOTICE 'MOTORISTA % NÃO ENCONTRADO EM MULTAS', BLOCO_A._MOTORISTA.NOME;
WHEN TOO_MANY_ROWS THEN
RAISE EXCEPTION 'MOTORISTA % POSSUI VARIAS MULTAS', BLOCO_A._MOTORISTA.NOME;
WHEN OTHERS THEN
RAISE NOTICE '%', SQLSTATE ;
RAISE NOTICE '%', SQLERRM;
END;
RETURN;
END;
$$ LANGUAGE PLPGSQL;

INSERT INTO EX_MOTORISTA VALUES ('369EF', 'ANA');
SELECT fm_msg('123AB');
SELECT * FROM ex_multa;

--Crie um procedimento fm_lista() o qual liste os motoristas (nome)
--e seu total de multas, caso o parametro sejam TODOS ou apenas de um CNH;
CREATE or REPLACE FUNCTION fm_lista() RETURNS integer AS $$
DECLARE
_MOTORISTA RECORD;
_MULTA RECORD;
BEGIN
RAISE NOTICE 'Listando Motoristas...';
FOR _MOTORISTA IN SELECT * FROM ex_motorista ORDER BY nome, totalmultas, cnh LOOP
RAISE NOTICE 'Motorista: % multas % CNH %', _MOTORISTA.nome,_MOTORISTA.totalmultas, _MOTORISTA.cnh;
END LOOP;
RAISE NOTICE 'Lista Concluída.';
RETURN 1;
END;
$$ LANGUAGE plpgsql;

select * from fm_lista();
select * from ex_motorista order by nome;

--Monte um procedimento fm_totalMultas() o qual retorne o total de multas
--de cada motorista. Use na função fm_lista()
CREATE OR REPLACE FUNCTION fm_totalMultas(pCNH CHAR(5)) RETURNS DECIMAL(5,2) AS
$$
DECLARE
_TOTAL DECIMAL(5,2) :=0;
BEGIN
SELECT COALESCE(SUM(VALOR)) AS VALOR
INTO _TOTAL FROM EX_MULTA WHERE CNH = pCNH;
RETURN _TOTAL;
END;
$$ LANGUAGE PLPGSQL;

select * from ex_multa;
SELECT fm_totalMultas('321AB');

CREATE OR REPLACE FUNCTION fm_atualtotalMultas(pCNH char(5)) RETURNS VOID AS
$$
BEGIN
IF pCNH IS NULL THEN
RAISE EXCEPTION 'CNH NÃO PODE SER NULO';
END IF;
IF (SELECT fm_totalMultas(pCNH))>0 THEN
UPDATE EX_MOTORISTA
SET TOTALMULTAS = (SELECT fm_totalMultas(pCNH))
WHERE CNH = pCNH;
END IF;
RETURN;
END;
$$
LANGUAGE PLPGSQL;

SELECT fm_atualtotalMultas('123AB');