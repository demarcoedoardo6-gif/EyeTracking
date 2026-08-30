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

% Prima Query: Screening precoce
% Calcolo della media per ogni paziente:

Medie_Pazienti = groupsummary(Database_finale, {'ID_Paziente', 'Gruppo_sano_patologico'}, 'mean', {'Latenza_ms', 'Error_Rate_Perc'});

% Soglia di latenza e di errore rate media oltre la quale un soggetto sano viene considerato a rischio
Soglia_Rischio_latenza = 350;
Soglia_Rischio_errore_rate = 10;

% Soggetti del gruppo 'Controllo' con latenza media > soglia
Filtro_Sani_Anomali = strcmp(Medie_Pazienti.Gruppo_sano_patologico, 'Controllo') & (Medie_Pazienti.mean_Latenza_ms > Soglia_Rischio_latenza) & (Medie_Pazienti.mean_Error_Rate_Perc > Soglia_Rischio_errore_rate);

% Estrazione dei soggetti sani a rischio per screening clinico
Pazienti_A_Rischio = Medie_Pazienti(Filtro_Sani_Anomali, :);

disp(' ');
disp('SOGGETTI SANI A RISCHIO (SCREENING PRECOCE MULTI-PARAMETRICO)');
disp(Pazienti_A_Rischio(:, {'ID_Paziente', 'mean_Latenza_ms', 'mean_Error_Rate_Perc'}));

% Seconda Query: Teoria della riserva cognitiva, effetto della scolarità sulle performance  

% Verifichiamo se un alto livello di istruzione riduce la percentuale 
% di errore nei pazienti, raggruppandoli in due fasce: "Fino al Diploma" e "Laurea".

Livello_Istruzione = strings(height(Database_finale), 1); %crea un vettore colonna temporaneo composto da stringhe vuote

Livello_Istruzione(Database_finale.Scolarita <= 13) = "1. Fino al Diploma"; %passa in rassegna il vettore colonna e se soddisfatta la condizione sostituisce lo spazio vuoto 
Livello_Istruzione(Database_finale.Scolarita > 13)  = "2. Laurea (Alta scolarita)";

Database_finale.Fascia_Scolarita = Livello_Istruzione; %inserimento di una nuova colonna nel database

Analisi_Riserva = groupsummary(Database_finale, {'Gruppo_sano_patologico', 'Fascia_Scolarita'}, 'mean', 'Error_Rate_Perc'); %incrocia le due colonne di raggruppamento e calcola la percentuale di errore medio per ciascuna combinazione  

disp(' ');
disp('TEST DELLA RISERVA COGNITIVA: SCOLARITA vs ERROR RATE');
disp(Analisi_Riserva(:, {'Gruppo_sano_patologico', 'Fascia_Scolarita', 'mean_Error_Rate_Perc'})); %selezione solo delle tre colonne

% Terza Query: Ricerca di Ipometria e Bradicinesia nel Morbo di Parkinson

% Filtraggio del database per mantenere i soggetti di controllo e i pazienti con Parkinson.
Filtro_Parkinson = strcmp(Database_finale.Gruppo_sano_patologico, 'Parkinson') | strcmp(Database_finale.Gruppo_sano_patologico, 'Controllo');
Dati_Parkinson_Sani = Database_finale(Filtro_Parkinson, :);

% Calcolo dell'ampiezza media e la velocità media incrociando i due gruppi.
Analisi_Ipometria = groupsummary(Dati_Parkinson_Sani, 'Gruppo_sano_patologico', 'mean', {'Ampiezza_deg', 'Velocita_Picco_deg_s'});

% 3. Stampa dei risultati per evidenziare il deficit motorio
disp(' ');
disp('ANALISI DEI DEFICIT OCULOMOTORI: PARKINSON vs CONTROLLO');
disp(Analisi_Ipometria(:, {'Gruppo_sano_patologico', 'mean_Ampiezza_deg', 'mean_Velocita_Picco_deg_s'}));










% FASE 4: SUPPORTO DECISIONALE CON MACHINE LEARNING (EXPLAINABLE AI)

% Addestramento di un modello per prevedere automaticamente se un paziente appartiene al gruppo "Controllo" o "Parkinson/Alzheimer".

% Preparazione dei Dati (Feature e Target) ---
% Definizione dei parametri oculomotori che l'algoritmo deve studiare (Input)
Variabili_Input = {'Latenza_ms', 'Error_Rate_Perc', 'Ampiezza_deg', 'Velocita_Picco_deg_s'};

% Estrazioni dal Database_finale solo dei dati clinici (X) e la diagnosi (Y)
X_Dati = Database_finale(:, Variabili_Input);
Y_Etichette = Database_finale.Gruppo_sano_patologico;

% Addestramento del Modello e uso MaxNumSplits per limitare la profondità dell'albero 
Modello_Diagnostico = fitctree(X_Dati, Y_Etichette, 'MaxNumSplits', 5);

disp(' ');
disp('MODELLO DI MACHINE LEARNING ADDESTRATO CON SUCCESSO!');

% Generazione il grafico ad albero per vedere le regole cliniche imparate
view(Modello_Diagnostico, 'Mode', 'graph');









%%  5.1 Generazione Tracciato Oculomotore Sintetico

% Creazione dell'asse del tempo (1 secondo diviso in 1000 millisecondi)
Tempo_ms = 1:1000; 

% Impostazione dei parametri presi dal nostro Albero Decisionale
Latenza_Sano = 250;  Ampiezza_Sano = 22; % Sano: parte presto, arriva in alto
Latenza_Park = 480;  Ampiezza_Park = 12; % Parkinson: parte tardi, movimento corto (Ipometria)
Latenza_Alz  = 550;  Ampiezza_Alz  = 20; % Alzheimer: parte tardissimo, ma movimento quasi normale

% 3. Formula matematica (Sigmoide) per simulare lo scatto dell'occhio per fare la curva a S. "-Latenza" sposta l'inizio a destra (ritardo), mentre il divisore finale (es. /25) schiaccia la pendenza per simulare la lentezza motoria. 
Onda_Sano = Ampiezza_Sano ./ (1 + exp(-(Tempo_ms - Latenza_Sano) / 10));
Onda_Park = Ampiezza_Park ./ (1 + exp(-(Tempo_ms - Latenza_Park) / 25));
Onda_Alz  = Ampiezza_Alz  ./ (1 + exp(-(Tempo_ms - Latenza_Alz)  / 12));

% 4. Disegniamo il monitor clinico
figure('Name', 'Tracciato Oculomotore', 'Color', [0.1 0.1 0.1]); 
plot(Tempo_ms, Onda_Sano, 'Color', [0.2 0.9 0.4], 'LineWidth', 3); hold on; % Verde   %hold on serve per sovrapporle
plot(Tempo_ms, Onda_Park, 'Color', [0.9 0.2 0.3], 'LineWidth', 3);          % Rosso
plot(Tempo_ms, Onda_Alz,  'Color', [0.2 0.7 0.9], 'LineWidth', 3);          % Azzurro

% 5. Formattazione con comandi grafici 
set(gca, 'Color', [0.15 0.15 0.15], 'XColor', 'white', 'YColor', 'white');
title('Simulazione Oculomotoria: Sano vs Parkinson vs Alzheimer', 'Color', 'white');
xlabel('Tempo (millisecondi)', 'Color', 'white');
ylabel('Posizione Occhio (gradi)', 'Color', 'white');
legend({'Controllo (Sano)', 'Parkinson', 'Alzheimer'}, 'TextColor', 'white', 'Color', [0.2 0.2 0.2], 'Location', 'northwest');
grid on;




