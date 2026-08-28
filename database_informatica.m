%Caricamento dei dati, presi da excell e convertiti in csv
Tabella_Pazienti = readtable('paziente.csv');
Tabella_Diagnosi = readtable('diagnosi.csv');
Tabella_Acquisizione = readtable('acquisizione.csv');
Tabella_metriche = readtable('metriche.csv', 'Delimiter', ';', 'DecimalSeparator',',');

%Creazione del database vero e proprio
Pazienti_completi = outerjoin(Tabella_Pazienti,Tabella_Diagnosi,'Keys','ID_Paziente','MergeKeys',true,'Type','left');  %MergeKeys serve per evitare creazione di due colonne distinte in pazienti 
Dati_EyeTracking = innerjoin(Tabella_Acquisizione,Tabella_metriche,'Keys','ID_Acquisizione');                          %Type left specifica di mantenere i pazienti della tabella di sinistra anche se non trovano un corrispettivo a quella di destra
Database_finale = innerjoin(Pazienti_completi,Dati_EyeTracking, 'Keys','ID_Paziente');
Database_finale = sortrows(Database_finale, 'ID_Acquisizione');

%Prima Query: Screening precoce
%Calcolo della media per ogni paziente:

Medie_Pazienti = groupsummary(Database_finale, {'ID_Paziente', 'Gruppo_sano_patologico'}, 'mean', {'Latenza_ms', 'Error_Rate_Perc'});

% Soglia di latenza e di errore rate media oltre la quale un soggetto sano viene considerato a rischio
Soglia_Rischio_latenza = 350;
Soglia_Rischio_errore_rate = 10;

%Soggetti del gruppo 'Controllo' con latenza media > soglia
Filtro_Sani_Anomali = strcmp(Medie_Pazienti.Gruppo_sano_patologico, 'Controllo') & (Medie_Pazienti.mean_Latenza_ms > Soglia_Rischio_latenza) & (Medie_Pazienti.mean_Error_Rate_Perc > Soglia_Rischio_errore_rate);

% Estrazione dei soggetti sani a rischio per screening clinico
Pazienti_A_Rischio = Medie_Pazienti(Filtro_Sani_Anomali, :);

disp(' ');
disp('SOGGETTI SANI A RISCHIO (SCREENING PRECOCE MULTI-PARAMETRICO)');
disp(Pazienti_A_Rischio(:, {'ID_Paziente', 'mean_Latenza_ms', 'mean_Error_Rate_Perc'}));