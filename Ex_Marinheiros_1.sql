CREATE SCHEMA db_MARINHEIROS;
USE db_MARINHEIROS;

CREATE TABLE MARINHEIROS (
id_marin integer primary key,
nome_marin varchar (100),
avaliacao integer,
idade real
);

CREATE TABLE RESERVAS (
id integer primary key,
id_marin integer ,
id_barco integer,
dia date
);

CREATE TABLE BARCOS (
id_barco integer primary key,
nome_barco varchar (100),
cor varchar (50)
);

CREATE TABLE TOTAL_RESERVAS (
 id_marin INT PRIMARY KEY,
 total INT 

);

CREATE TABLE AUDITORIA_RESERVAS (
id_audioria INT AUTO_INCREMENT PRIMARY KEY,
id_marin INT REFERENCES MARINHEIROS,
 nome_barco VARCHAR (100),
 data_reserva DATE ,
 data_log DATETIME

);

CREATE TABLE log_reservas (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  id_marin INT,
  id_barco INT,
  data_reserva DATE,
  data_log DATETIME
);



CREATE TABLE historico_marinheiros (
id_log  INT AUTO_INCREMENT PRIMARY KEY,
id_marin  INT, 
campo VARCHAR (50),
valor_antigo VARCHAR (100),
valor_novo VARCHAR (100),
data_alteracao DATETIME

);

INSERT INTO MARINHEIROS
VALUES 
(22,'Dustin',7,45.0),
(29,'Brutus',1,33.0),
(31,'Lubber',8,55.5),
(32,'Andy',8,25.5),
(58,'Rusty',10,35.0),
(64,'Horatio',7,35.0),
(71,'Zorba',10,16.0),
(74,'Horatio',9,35.0),
(85,'Art',3,25.5),
(95,'Bob',3,63.5);

INSERT INTO RESERVAS VALUES
(1, 22, 101, '1998-10-10'),
(2, 22, 102, '1998-10-10'),
(3, 22, 103, '1998-10-08'),
(4, 22, 104, '1998-10-07'),
(5, 31, 102, '1998-11-10'),
(6, 31, 103, '1998-11-06'),
(7, 31, 104, '1998-11-12'),
(8, 64, 101, '1998-09-05'),
(9, 64, 102, '1998-09-05'),
(10, 74, 103, '1998-09-08');


INSERT INTO BARCOS 
 VALUES 

(101,'Interlake','Azul'),
(102,'Interlake','vermelho'),
(103,'Clipper','Verde'),
(104,'Marine','Vermelho');

/*CRIE 5 TRIGGERS PARA GESTÃO DA MARINA. PODE SER PARA QUALQUER SITUAÇÃO.*/


DELIMITER $$

CREATE TRIGGER TRG_LIMITE_RESERVAS_DIA
BEFORE INSERT ON  RESERVAS 
FOR EACH ROW 
BEGIN
DECLARE TOTAL INT ;
SELECT COUNT(*) INTO TOTAL
FROM RESERVAS 
WHERE id_marin = NEW.id_marin AND dia = NEW.dia;

IF total >= 2 THEN 
SIGNAL SQLSTATE '45000'
SET  MESSAGE_TEXT = 'MARINHEIRO JÁ POSSUI 2 RESERVAS NESTE DIA';
END  IF;
END $$
DELIMITER ;


/* ------------------------------------------------------------------------------------------------ */
DELIMITER $$
CREATE TRIGGER TRG_HISTORICO_MARINHEIROS
AFTER UPDATE ON MARINHEIROS
FOR EACH ROW 
BEGIN 
IF  OLD.nome_marin <>  NEW.nome_marin THEN
INSERT INTO historico_marinheiros (id_marin , campo , valor_antigo, valor_novo,data_alteracao)
VALUES (NEW.id_marin , 'nome_marinheiro', OLD.nome_marin, NEW.nome_marin, NOW());
END IF;

IF OLD.avaliacao <> NEW.avaliacao THEN
INSERT INTO historico_marinheiro (id_marin, campo, valor_antigo, valor_novo, data_alteracao)
VALUES (NEW.id_marin, 'avaliacao', OLD.avaliacao, NEW.avaliacao , NOW());
END IF ;

  IF OLD.idade <> NEW.idade THEN
    INSERT INTO historico_marinheiros (id_marin, campo, valor_antigo, valor_novo, data_alteracao)
    VALUES (NEW.id_marin, 'idade', OLD.idade, NEW.idade, NOW());
  END IF;
  END $$
DELIMITER ;

/* ------------------------------------------------------------------------------------------------ */


DELIMITER $$
CREATE TRIGGER TRG_BLOQUEAR_AVALIACAO_BAIXA
BEFORE INSERT ON RESERVAS 
FOR EACH ROW 
BEGIN

DECLARE AVALIACAO_MARIN INT ;
SELECT AVALIACAO INTO AVALIACAO_MARIN
FROM MARINHEIROS
WHERE id_marin = NEW.id_marin;
IF AVALIACAO_MARIN < 2 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'MARINHEIRO COM  AVALIAÇÃO MUITO A BAIXO DA MÉDIA. RESERVA NÃO PERMITIDA.';
END IF;
END $$
DELIMITER ;

/* ------------------------------------------------------------------------------------------------ */

DELIMITER $$
CREATE TRIGGER TRG_BLOQUEAR_NOME_DUPLICADO
BEFORE INSERT ON RESERVAS 
FOR EACH ROW 
BEGIN 
DECLARE NOME VARCHAR (100);
DECLARE TOTAL INT;

SELECT nome_marin INTO NOME 
FROM MARINHEIROS
WHERE id_marin = new.id_marin;
SELECT COUNT(*) INTO TOTAL
FROM  MARINHEIROS
WHERE nome_marin = nome;
IF total > 1  THEN 
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'MARINHEIRO COM NOME DUPLICADO NÃO PODE RESERVAR.';
END IF;
END $$
DELIMITER ;
 
/* ------------------------------------------------------------------------------------------------ */


DELIMITER $$
CREATE TRIGGER TRG_AUDITORIA_RESERVA
AFTER INSERT ON RESERVAS 
FOR EACH ROW
BEGIN
DECLARE nome_barco VARCHAR (100);
 SELECT nome_barco  INTO nome_barco
 FROM BARCOS
 WHERE id_barco = NEW.id_barco;
 
 INSERT INTO AUDITORIA_RESERVAS(id_marin,nome_barco,data_reserva,data_log)
 VALUES (NEW.id_marin, nome_barco,NEW.dia, NOW());
 END$$

DELIMITER ;