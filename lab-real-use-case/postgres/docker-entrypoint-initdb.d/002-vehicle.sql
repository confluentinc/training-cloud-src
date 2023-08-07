-- timestamp doesn't do what I was hoping
-- https://stackoverflow.com/questions/1035980/update-timestamp-when-row-is-updated-in-postgresql
CREATE TABLE vehicleinfo (
    id SERIAL PRIMARY KEY not null,
    vehicleid integer not null,
    make varchar(50) not null,
    model varchar(50) not null,
    regdate varchar(50) not null,
    plate varchar(50) not null,
    ts timestamp default current_timestamp not null
);


INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (1, 'MAN', 'Lion''s City', '2015-06-19', 'ABC-123');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (2, 'MAN', 'Lion''s City', '2015-06-19', 'DEF-456');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (3, 'MAN', 'Lion''s City', '2015-06-19', 'GHI-789');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (4, 'MAN', 'Lion''s City', '2015-06-19', 'JKL-012');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (5, 'MAN', 'Lion''s City', '2015-06-19', 'MNO-345');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (6, 'MAN', 'Lion''s City', '2015-06-19', 'PQR-678');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (7, 'MAN', 'Lion''s City', '2015-06-19', 'STU-901');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (8, 'MAN', 'Lion''s City', '2015-06-19', 'VWX-234');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (9, 'MAN', 'Lion''s City', '2015-06-19', 'YZA-567');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (10, 'MAN', 'Lion''s City', '2015-06-19', 'BCD-890');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (11, 'Mercedes-Benz', 'Citaro', '2019-02-11', 'EFG-123');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (12, 'Mercedes-Benz', 'Citaro', '2019-02-11', 'HIJ-456');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (13, 'Mercedes-Benz', 'Citaro', '2019-02-11', 'KLM-789');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (14, 'Mercedes-Benz', 'Citaro', '2019-02-11', 'NOP-012');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (15, 'Mercedes-Benz', 'Citaro', '2019-02-11', 'QRS-345');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (16, 'Mercedes-Benz', 'Citaro', '2019-02-11', 'TUV-678');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (17, 'Mercedes-Benz', 'Citaro', '2019-05-17', 'VWX-901');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (18, 'Mercedes-Benz', 'Citaro', '2019-05-17', 'YZA-234');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (19, 'Mercedes-Benz', 'Citaro', '2019-05-17', 'BCD-567');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (20, 'Mercedes-Benz', 'Citaro', '2019-05-17', 'EFG-890');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (21, 'Mercedes-Benz', 'Citaro', '2019-05-17', 'HIJ-123');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (22, 'Mercedes-Benz', 'Citaro', '2019-05-17', 'KLM-456');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (23, 'Mercedes-Benz', 'Citaro', '2020-01-20', 'NOP-789');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (24, 'Mercedes-Benz', 'Citaro', '2020-01-20', 'QRS-012');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (25, 'Mercedes-Benz', 'Citaro', '2020-01-20', 'TUV-345');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (26, 'Volvo', '7900', '2023-03-25', 'VWX-678');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (27, 'Volvo', '7900', '2023-03-25', 'YZA-901');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (28, 'Volvo', '7900', '2023-03-25', 'BCD-234');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (29, 'Volvo', '7900', '2023-03-25', 'EFG-567');

INSERT INTO vehicleinfo (vehicleid, make, model, regdate, plate) VALUES
    (30, 'Volvo', '7900', '2023-03-25', 'HIJ-890');
