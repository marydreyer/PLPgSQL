--Tabela com empregados
create table tr_emp (
idEmp integer primary key,
nome varchar(50) not null,
maxSal decimal(9,2) not null check (maxsal > 0),
dth_inc timestamp,
usu_inc varchar(20),
dth_atu timestamp,
usu_atu varchar(20));

--Tabela com salarios
create table tr_sal_emp (
idSal_emp integer primary key,
 idEmp integer references tr_emp(idEmp) not null,
dtIni date not null,
dtFim date null check (dtFim > dtIni),
sal decimal(9,2) not null,
usu_inc varchar(20),
dth_inc timestamp,
usu_atu varchar(20),
dth_atu timestamp);

--guarda o resumo da qnt d promocoes q ocorreram no mes
create table tr_promovido ( 
anoMes integer primary key,
qtd integer check (qtd > 0));

--[Selects]--
SELECT * from tr_emp
SELECT * from tr_sal_emp
SELECT * from tr_promovido
--[Inserts e Updates]--
INSERT INTO tr_emp(idEmp, nome, maxSal)VALUES(1, 'Indiana', 3500)
INSERT INTO tr_emp(idEmp, nome, maxSal)VALUES(2, 'Jones', 5000)
INSERT INTO tr_emp(idEmp, nome, maxSal)VALUES(3, 'Vader', 7500)
--Alterar salario
UPDATE tr_emp set maxSal = 10000 where idEmp = 3;
--Incluir salario a um empregado, testa a regra da a
INSERT INTO tr_sal_emp(idSal_emp, idEmp, dtInit, dtFim, sal)VALUES(1, 1,'01-01-2021', '31-12-2021', 2500)
--testa a regra da b
INSERT INTO tr_sal_emp(idSal_emp, idEmp, dtInit, dtFim, sal)VALUES(1, 1,'01-01-2021', '31-12-2021', 1500)
--testa a regra da c posterior dezembro de 2010
INSERT INTO tr_sal_emp(idSal_emp, idEmp, dtInit, dtFim, sal)VALUES(1, 1,'01-01-2020', '31-12-2020', 4500)
--testa a regra da c anterior janeiro de 2012
INSERT INTO tr_sal_emp(idSal_emp, idEmp, dtInit, dtFim, sal)VALUES(1, 1,'01-01-2011', '31-12-211', 3500)




--[funcao - 1 - A B C]--
CREATE FUNCTION regra_A_B_C_E() RETURNS TRIGGER AS 
$$
BEGIN
--(a) 
	IF NEW.sal IS >= tr_emp.maxSal THEN
		RAISE EXCEPTION 'Desculpe, o salario não pode ser superior ao limite de salario';
	END IF;
--(b) 
	IF (TG_OP = 'UPDATE') AND OLD.dtIni OR OLD.dtFim IS BETWEEN NEW.dtIni and NEW.dtFim THEN
		RAISE EXCEPTION 'Desculpe, data invalida. Nao pode ter interseccao de registros de promocao do mesmo empregado ';
	END IF;
--(c) 
	IF NEW.dtIni IS >= '01-12-2010' THEN SET dtFim = null;
	END IF;
	IF NEW.dtIni IS <= '01-01-2012' AND idEmp=10 OR idEmp=20 OR idEmp=30 THEN
	SET dtFim = '31-12-2012';
	END IF;
--(e) 
	IF (TG_OP = 'INSERT') THEN
		PERFORM * FROM tr_promovido WHERE anoMes = TO_CHAR(dth_inc , 'mm-yyyy');
	IF NOT FOUND
		INSERT INTO tr_promovido(anoMes, qtd) VALUES(TO_CHAR(dth_inc , 'mm-yyyy'), 1);
	ELSE 
		UPDATE tr_promovido SET qtd = OLD.qtd+1 WHERE anoMes = TO_CHAR(dth_inc , 'mm-yyyy');
	END IF;
	IF (TG_OP = 'DELETE') THEN
		PERFORM * FROM tr_promovido WHERE anoMes = TO_CHAR(dth_inc , 'mm-yyyy');
	IF NOT FOUND
		DELETE tr_promovido SET qtd = OLD.qtd - 1 WHERE anoMes = TO_CHAR(dth_inc , 'mm-yyyy');
	END IF;
		
RETURN NEW;
END;
$$
LANGUAGE plpgsql;

--[funcao - 1 - D]--

CREATE FUNCTION regra_D() RETURNS TRIGGER AS 
$$
BEGIN
--(d) 
	IF (TG_OP = 'INSERT') THEN
	INSERT INTO tr_sal_em(usu_inc, dth_inc) VALUES(CURRENT_USER, CURRENT_TIMESTAMP);
	RETURN NEW;
	ELSIF (TG_OP = 'UPDATE') THEN
	INSERT INTO tr_sal_em(usu_atu, dth_atu) VALUES(CURRENT_USER, CURRENT_TIMESTAMP);
	RETURN NEW;
	END IF;
RETURN NEW;
END;
$$
LANGUAGE plpgsql;

--[triggers - 1]--

CREATE TRIGGER tr_regra_A_B_C_E BEFORE INSERT OR UPDATE
ON tr_sal_emp
FOR EACH ROW EXECUTE PROCEDURE regra_A_B_C_E();

CREATE TRIGGER tr_regra_D AFTER INSERT OR UPDATE
ON tr_sal_emp
FOR EACH ROW EXECUTE PROCEDURE regra_D();


--[tabela log]
CREATE TABLE auditoria(
cod serial primary key,
op_audit char(1) not null,
autor_audit char(20) not null,
data_audit timestamp not null,
sal_old_audit decimal(9,2) not null,
sal_new_audit decimal(9,2) not null
);

--[funcao]
CREATE FUNCTION gera_auditoria() RETURNS TRIGGER AS 
$$
BEGIN
	INSERT INTO auditoria(op_audit, autor_audit, data_audit, sal_old_audit, sal_new_audit) 
	VALUES (TG_OP, user, data, NEW.sal, OLD.sal)
END;
$$
LANGUAGE plpgsql;

--[trigger (b)]
-- Criar trigger p/ popular a tab de auditoria conforme são realizadas as operações na tab TR_EMP;
CREATE TRIGGER tr_gera_auditoria AFTER INSERT OR UPDATE OR DELETE
ON tr_emp
FOR EACH ROW EXECUTE PROCEDURE gera_auditoria();