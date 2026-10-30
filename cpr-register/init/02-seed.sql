-- Example data. One citizen's firstname is the flag: FLAG{BaD_PaSS}
-- (The attacker only needs to read the table to find it.)

INSERT INTO citizens (cpr, firstname, lastname, address, postal_code, city, phone, gp_doctor) VALUES
('010579-1234', 'Lars',          'Nielsen',    'Vestergade 12',        '8000', 'Aarhus C',     '20304050', 'Dr. Holm'),
('230982-5678', 'Mette',         'Jensen',     'Nørrebrogade 45',      '2200', 'København N',  '31415926', 'Dr. Holm'),
('150344-9876', 'Hans',          'Pedersen',   'Skolegade 3',          '5000', 'Odense C',     '27182818', 'Dr. Lund'),
('290701-4321', 'Sofie',         'Andersen',   'Havnevej 8',           '9000', 'Aalborg',      '16180339', 'Dr. Lund'),
('040488-1111', 'Emil',          'Christensen','Bakkedraget 21',       '7100', 'Vejle',        '14142135', 'Dr. Holm'),
('120256-2222', 'Anne',          'Larsen',     'Søndergade 77',        '6700', 'Esbjerg',      '17320508', 'Dr. Bisgaard'),
('310893-3333', 'FLAG{BaD_PaSS}','Mortensen',  'Gammel Kongevej 100',  '1850', 'Frederiksberg','23606797', 'Dr. Bisgaard'),
('070767-4444', 'Peter',         'Hansen',     'Møllevej 9',           '4000', 'Roskilde',     '26457513', 'Dr. Lund'),
('181199-5555', 'Camilla',       'Rasmussen',  'Strandvejen 200',      '2900', 'Hellerup',     '33166247', 'Dr. Holm'),
('020630-6666', 'Jørgen',        'Thomsen',    'Kirkeallé 14',         '3000', 'Helsingør',    '37416573', 'Dr. Bisgaard'),
('250585-7777', 'Louise',        'Poulsen',    'Fasanvej 5',           '2000', 'Frederiksberg','44721359', 'Dr. Lund'),
('140472-8888', 'Henrik',        'Johansen',   'Industrivej 30',       '8700', 'Horsens',      '46410161', 'Dr. Holm'),
('090909-9999', 'Maria',         'Madsen',     'Toldbodgade 2',        '1253', 'København K',  '48989794', 'Dr. Bisgaard'),
('121212-1010', 'Kasper',        'Olsen',      'Ringvejen 88',         '8600', 'Silkeborg',    '50990195', 'Dr. Lund'),
('030303-2020', 'Ida',           'Kristensen', 'Parkvej 11',           '5700', 'Svendborg',    '52915026', 'Dr. Holm');

INSERT INTO audit_log (actor, action) VALUES
('admin', 'Initial bulk import from legacy mainframe'),
('admin', 'Password policy review postponed (TODO)'),
('svc_backup', 'Nightly export to \\\\fileserver\\backups completed');
