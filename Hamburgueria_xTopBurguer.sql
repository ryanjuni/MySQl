/*
Hamburgueria xTopBurguer: Tabelas Principais

    Cliente: Armazena informações sobre os clientes.

    Produto: Cadastra os produtos vendidos pela hamburgueria (hambúrgueres, batatas, refrigerantes, etc.).

    Pedido: Registra os pedidos feitos pelos clientes.

    ItemPedido: Relaciona pedidos com produtos.

    Caixa: Registra as transações financeiras diárias.
 
*/
CREATE SCHEMA HAMBURGUERIA_XTOPBURGUER;
USE HAMBURGUERIA_XTOPBURGUER;
-- Tabela Cliente
CREATE TABLE Cliente (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(15) NOT NULL,
    endereco VARCHAR(255) NOT NULL
);

-- Tabela Produto
CREATE TABLE Produto (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(100) NOT NULL,
    preco_custo DECIMAL(10, 2) DEFAULT 0,
    preco_venda DECIMAL(10, 2) DEFAULT 0,
    estoque int Not null
);

-- Produtos
INSERT INTO Produto (descricao,preco_custo, preco_venda,estoque) VALUES
('xTop Simples',10, 15.00,12),
('xTop Duplo',13, 25.00,23),
('xTop Bacon',18, 31.00,22),
('xTop Tudo',22, 45.00,29),
('xTop Vegano', 29,40.00,18),
('Batata Frita P',4, 8.00,50),
('Batata Frita M',7, 12.00,60),
('Batata Frita G',12, 18.00,45),
('Refrigerante Lata',3, 8.00,90),
('Refrigerante 1L',6, 11.00,45),
('Refrigerante 2L',8, 15.00,33);
-- Tabela Pedido
CREATE TABLE Pedido (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    data_pedido DATE NOT NULL,
    hora_pedido TIME NOT NULL,
	data_pagamento DATE,
	forma_pagamento VARCHAR(50),
	tempo_estimado_entrega INT ,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente)
);

-- Tabela ItemPedido
CREATE TABLE ItemPedido (
    id_item INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    data_pedido DATE,
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto)
);


CREATE TABLE MOVIMENTACAO_FIANANCEIRA (
  id_movimentacao INT AUTO_INCREMENT PRIMARY KEY,
  Data_Movimento DATE,
  forma_pagamento VARCHAR(50),
  valor DECIMAL(10,2)
);



CREATE TABLE previsaoDemada (
    id_produto INT NOT NULL,
    data_previsao DATE NOT NULL,
    quantidade_prevista INT,
    PRIMARY KEY (id_produto, data_previsao),
    FOREIGN KEY (id_produto) REFERENCES Produto(id_produto)
);




-- Tabela Caixa
CREATE TABLE Caixa (
    id_caixa INT PRIMARY KEY AUTO_INCREMENT,
    data DATE NOT NULL,
    entrada DECIMAL(15, 2) DEFAULT 0,
    saida DECIMAL(15, 2) DEFAULT 0,
    saldo DECIMAL(15, 2) NOT NULL
);

-- Inserção de dados de exemplo

-- Clientes
INSERT INTO Cliente (nome, telefone, endereco) VALUES
('João Silva', '11987654321', 'Rua das Flores, 123'),
('Maria Souza', '11912345678', 'Avenida Brasil, 456'),
('Carlos Oliveira', '11955554444', 'Rua das Palmeiras, 789'),
('Janule Oliveira', '44333334555', 'Rua das casas, 79'),
('Teclaudio Gomes', '12344232222', 'Rua das hortaliças, 78');


-- Pedidos
INSERT INTO Pedido (id_cliente, data_pedido, hora_pedido) VALUES
(1, '2025-10-23', '18:30:00'),
(2, '2025-10-23', '19:15:00'),
(3, '2025-10-23', '20:00:00'),
(4, '2025-10-23', '19:15:00'),
(5, '2025-10-23', '20:15:00');

-- Itens dos Pedidos
INSERT INTO ItemPedido (id_pedido, id_produto, quantidade) VALUES
(1, 1, 1),
(1, 2, 1),
(2, 3, 2),
(3, 4, 1),
(4, 4, 1),
(4, 5, 1),
(4, 7, 1),
(4, 7, 1),
(4, 10, 1),
(5, 5, 1),
(5, 8, 1),
(5, 9, 1);

/*
1. Trigger para controlar estoque antes de inserir item no pedido
Antes de inserir um item em ItemPedido, verifica se o estoque do produto 
é suficiente para a quantidade solicitada. Se não for, 
aborta a inserção com erro. Caso positivo, 
atualiza o estoque subtraindo a quantidade.
*/
DELIMITER //

CREATE TRIGGER trg_itempedido_before_insert
BEFORE INSERT ON ItemPedido
FOR EACH ROW
BEGIN
  DECLARE estoque_atual INT;

  SELECT estoque INTO estoque_atual FROM Produto WHERE id_produto = NEW.id_produto;

  IF estoque_atual IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto não encontrado.';
  ELSEIF estoque_atual < NEW.quantidade THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para o produto.';
  ELSE
    UPDATE Produto SET estoque = estoque - NEW.quantidade WHERE id_produto = NEW.id_produto;
  END IF;
END;
//

DELIMITER ;

/*
2. Trigger para restaurar estoque após remoção de item do pedido
Após deletar um item de pedido, repõe a quantidade do produto no estoque.
*/
DELIMITER //
CREATE TRIGGER trg_itempedido_after_delete
AFTER DELETE ON ItemPedido
FOR EACH ROW
BEGIN
  UPDATE Produto
  SET estoque = estoque + OLD.quantidade
  WHERE id_produto = OLD.id_produto;
END //
DELIMITER ;


/*
Crie uma trigger chamada trg_itempedido_atualiza_caixa que seja executada APÓS a inserção de um registro na tabela ItemPedido. 
Esta trigger deve:
    Buscar a data do pedido relacionado ao item inserido (consultando a tabela Pedido).
    Calcular o valor do item multiplicando o preço de venda do produto pela quantidade inserida (consultando a tabela Produto).
    Verificar se já existe um registro no caixa para a data do pedido:
        Se NÃO existir: Inserir um novo registro na tabela Caixa com:
 - `data` = data do pedido
 - `entrada` = valor do item
 - `saida` = 0
 - `saldo` = valor do item
    Se EXISTIR: Atualizar o registro existente, somando o valor do item às colunas entrada e saldo.
    Caso a data do pedido não seja encontrada (por algum erro), usar a data atual (CURDATE()).
*/

-- Primeiro, remova a trigger antiga
DROP TRIGGER IF EXISTS trg_itempedido_atualiza_caixa;

DELIMITER //

CREATE TRIGGER trg_itempedido_atualiza_caixa
AFTER INSERT ON ItemPedido
FOR EACH ROW
BEGIN
  DECLARE v_valor_item DECIMAL(15,2);
  DECLARE v_data_pedido DATE;
  DECLARE v_caixa_existe INT DEFAULT 0;

  -- Busca a data do pedido relacionado ao item
  SELECT p.data_pedido 
  INTO v_data_pedido 
  FROM Pedido p
  WHERE p.id_pedido = NEW.id_pedido;
  
  -- Calcula o valor do item inserido
  SELECT pr.preco_venda * NEW.quantidade
  INTO v_valor_item
  FROM Produto pr
  WHERE pr.id_produto = NEW.id_produto;

  -- Se não encontrou a data do pedido, usa a data atual
  IF v_data_pedido IS NULL THEN
    SET v_data_pedido = CURDATE();
  END IF;

  -- Verifica se já existe registro no caixa para ESSA DATA ESPECÍFICA
  SELECT COUNT(*) 
  INTO v_caixa_existe 
  FROM Caixa 
  WHERE data = v_data_pedido;

  IF v_caixa_existe = 0 THEN
    -- NÃO EXISTE: Insere novo registro no caixa para essa data
    INSERT INTO Caixa (data, entrada, saida, saldo) 
    VALUES (v_data_pedido, v_valor_item, 0, v_valor_item);
  ELSE
    -- EXISTE: Atualiza APENAS a linha da data específica
    UPDATE Caixa
    SET entrada = entrada + v_valor_item,
        saldo = saldo + v_valor_item
    WHERE data = v_data_pedido;
  END IF;
END;
//

DELIMITER ;


-- 1. Insira o pedido
INSERT INTO Pedido (id_cliente, data_pedido, hora_pedido) 
VALUES (1, '2025-10-26', CURTIME());

-- 2. Verifique o ID
SELECT LAST_INSERT_ID() AS id_pedido;

-- 3. Insira um item (use o ID correto do pedido)
INSERT INTO ItemPedido (id_pedido, id_produto, quantidade) 
VALUES 
(11, 1, 1),
(11, 1, 1);
-- 4. Verifique o caixa
SELECT * FROM Caixa WHERE data = CURDATE();
SELECT * FROM Caixa;

/*-----------------------------------------------------------------------------------*/
DELIMITER $$
	CREATE TRIGGER trg_tempo_entrega
	AFTER INSERT ON ItemPedido
	FOR EACH ROW 
	BEGIN 
		 DECLARE V_qtd_total INT ;
		 DECLARE V_tempo INT;
		 
		 SELECT SUM(quantidade)
		 INTO V_qtd_total
		 FROM itemPedido
		 WHERE id_pedido = NEW.id_pedido;
		 
		 SET V_tempo = 20 + (V_qtd_total * 5);
		 UPDATE pedido
		 SET tempo_estimado_entrega = V_tempo
		 WHERE id_pedido = NEW.id_pedido;
	 END $$;

DELIMITER ;

/*-----------------------------------------------------------------------------------*/
INSERT INTO ItemPedido (id_pedido, id_produto, quantidade)
VALUES (1, 2, 3);

/*-----------------------------------------------------------------------------------*/


DELIMITER $$

CREATE TRIGGER  trg_Desconto
AFTER INSERT ON ItemPedido
FOR EACH ROW
	BEGIN
	  DECLARE v_total DECIMAL(10,2);

	  SELECT SUM(pr.preco_venda * ip.quantidade)
	  INTO v_total
	  FROM ItemPedido ip
	  JOIN Produto pr ON pr.id_produto = ip.id_produto
	  WHERE ip.id_pedido = NEW.id_pedido;

	  IF v_total > 100 THEN
		UPDATE Pedido 
		SET desconto = v_total * 0.10
		WHERE id_pedido = NEW.id_pedido;
  END IF;
END $$

DELIMITER ;



/*-----------------------------------------------------------------------------------*/
INSERT INTO ItemPedido (id_pedido, id_produto, quantidade)
VALUES (1, 3, 5);

/*-----------------------------------------------------------------------------------*/

DELIMITER $$
	CREATE TRIGGER TRG_MOVIMENTACAO_FIANANCEIRA
	AFTER INSERT ON pedido
	FOR EACH ROW
	BEGIN
		DECLARE v_valor_total DECIMAL (10,2);
		SELECT 
    SUM(pr.preco_venda * ip.quantidade)
INTO v_valor_total FROM
    ItemPedido ip
        JOIN
    Produto pr ON pr.id_produto = ip.id_produto
WHERE
    ip.id_pedido = NEW.id_pedido;

		INSERT INTO MOVIMENTACAO_FIANANCEIRA (Data_Movimento,forma_pagamento,valor)
		VALUES (NEW.data_pagamento, NEW.forma_pagamento ,v_valor_total);
	END $$;
DELIMITER ;
/*-----------------------------------------------------------------------------------*/
ALTER TABLE Cliente ADD COLUMN total_gasto DECIMAL(10,2) DEFAULT 0;
/*-----------------------------------------------------------------------------------*/
INSERT INTO Pedido (id_cliente, data_pagamento, forma_pagamento, tempo_estimado_entrega, desconto)
VALUES (1, CURDATE(), 'Cartão', NULL, NULL);

/*-----------------------------------------------------------------------------------*/


DELIMITER $$
CREATE TRIGGER TRG_PRVISAO_DEMANDA
AFTER INSERT ON itemPedido
FOR EACH ROW 
BEGIN
	DECLARE v_media_vendas INT;
	SELECT FLOOR(SUM(quantidade)/7)
	INTO v_media_vendas 
	FROM itemPedido
	WHERE id_produto = NEW.id_produto
	AND data_pedido >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
	INSERT INTO previsaoDemada (id_produto,data_previsao,quantidade_prevista)
	VALUES (NEW.id_produto,CURDATE(),v_media_vendas)
	ON DUPLICATE KEY UPDATE  quantidade_prevista = v_media_vendas;
END $$;
DELIMITER ;
/*-----------------------------------------------------------------------------------*/
INSERT INTO ItemPedido (id_pedido, id_produto, quantidade)
VALUES (2, 2, 4);

/*-----------------------------------------------------------------------------------*/

DELIMITER $$
CREATE TRIGGER TRG_PROMOVER_CLIENTE_VIP
AFTER INSERT ON Pedido
FOR  EACH ROW
BEGIN
	DECLARE v_total DECIMAL(10,2);
    
	SELECT SUM(pr.preco_venda * ip.quantidade)
	INTO v_total 
	FROM itemPedido ip
	JOIN Produto pr  ON pr.id_produto = ip.id_produto
	WHERE ip.id_pedido = NEW.id_pedido;
    
	UPDATE Cliente 
	SET total_gasto = total_gasto + v_total
	WHERE id_cliente = NEW.id_cliente;
    
    IF (SELECT total_gasto FROM Cliente WHERE id_cliente = NEW.id_cliente) > 1000 THEN 
    UPDATE Cliente
    SET tipo_cliente = 'VIP'
    WHERE id_cliente = NEW.id_cliente;
    END IF;
    END $$
DELIMITER ;
/*-----------------------------------------------------------------------------------*/
ALTER TABLE Pedido ADD COLUMN desconto DECIMAL(10,2) DEFAULT 0;
/*-----------------------------------------------------------------------------------*/
INSERT INTO ItemPedido (id_pedido, id_produto, quantidade)
VALUES (2, 2, 20);

/*-----------------------------------------------------------------------------------*/