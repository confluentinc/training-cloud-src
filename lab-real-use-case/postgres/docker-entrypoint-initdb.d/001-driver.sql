-- timestamp doesn't do what I was hoping
-- https://stackoverflow.com/questions/1035980/update-timestamp-when-row-is-updated-in-postgresql
CREATE TABLE driverinfo (
    id SERIAL PRIMARY KEY not null,
    driverid integer not null,
    firstname varchar(50) not null,
    lastname varchar(50) not null,
    dob varchar(50) not null,
    phone varchar(50) not null,
    email varchar(50) not null,
    ts timestamp default current_timestamp not null
);

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (1, 'Markku', 'Lehtonen', '1985-03-12', '+358-123456789', 'markku.lehtonen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (2, 'Anna', 'Virtanen', '1992-07-28', '+358-987654321', 'anna.virtanen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (3, 'Mikko', 'Nieminen', '1980-12-01', '+358-246813579', 'mikko.nieminen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (4, 'Laura', 'Koskinen', '1991-06-15', '+358-1122334455', 'laura.koskinen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (5, 'Ville', 'Järvinen', '1988-09-03', '+358-505050505', 'ville.jarvinen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (6, 'Riikka', 'Laine', '1994-02-18', '+358-777777777', 'riikka.laine@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (7, 'Jussi', 'Rantanen', '1982-11-20', '+358-999999999', 'jussi.rantanen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (8, 'Sofia', 'Mäkinen', '1990-05-09', '+358-654321987', 'sofia.makinen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (9, 'Antti', 'Karjalainen', '1987-08-25', '+358-246813579', 'antti.karjalainen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (10, 'Emilia', 'Hakala', '1993-01-11', '+358-1122334455', 'emilia.hakala@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (11, 'Eero', 'Kosonen', '1989-04-05', '+358-505050505', 'eero.kosonen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (12, 'Linda', 'Salonen', '1995-10-22', '+358-777777777', 'linda.salonen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (13, 'Janne', 'Heikkilä', '1983-07-07', '+358-999999999', 'janne.heikkila@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (14, 'Sara', 'Peltola', '1991-12-14', '+358-654321987', 'sara.peltola@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (15, 'Petri', 'Kallio', '1988-02-27', '+358-246813579', 'petri.kallio@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (16, 'Hanna', 'Lindholm', '1994-09-10', '+358-1122334455', 'hanna.lindholm@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (17, 'Ville', 'Turunen', '1980-12-23', '+358-777777777', 'ville.turunen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (18, 'Laura', 'Saari', '1996-05-08', '+358-999999999', 'laura.saari@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (19, 'Sami', 'Räsänen', '1984-09-19', '+358-654321987', 'sami.rasanen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (20, 'Maria', 'Ranta', '1992-02-14', '+358-246813579', 'maria.ranta@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (21, 'Juha', 'Aaltonen', '1987-06-27', '+358-1122334455', 'juha.aaltonen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (22, 'Tiina', 'Niemi', '1993-11-02', '+358-505050505', 'tiina.niemi@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (23, 'Matti', 'Mäkelä', '1985-03-15', '+358-777777777', 'matti.makela@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (24, 'Hanna', 'Virtanen', '1991-07-30', '+358-999999999', 'hanna.virtanen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (25, 'Markus', 'Koskinen', '1981-12-04', '+358-654321987', 'markus.koskinen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (26, 'Johanna', 'Mäntynen', '1990-06-17', '+358-246813579', 'johanna.mantynen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (27, 'Mikko', 'Leppänen', '1988-09-05', '+358-1122334455', 'mikko.leppanen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (28, 'Sanna', 'Korhonen', '1994-02-20', '+358-505050505', 'sanna.korhonen@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (29, 'Janne', 'Salmi', '1982-11-23', '+358-777777777', 'janne.salmi@email.com');

INSERT INTO driverinfo (driverid, firstname, lastname, dob, phone, email) VALUES
    (30, 'Niina', 'Virta', '1990-05-10', '+358-999999999', 'niina.virta@email.com');
