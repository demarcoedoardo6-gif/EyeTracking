function referto_clinico(Database_finale, ID_Paziente)
    
    % --- 1. CONTROLLI DI SICUREZZA ANTI-CRASH ---
    % Se l'utente preme "Play" per sbaglio senza passare i dati
    if nargin < 2
        disp('Errore: Devi fornire sia il database che l''ID del paziente.');
        return;
    end
    
    % Se la variabile passata non è una tabella
    if ~istable(Database_finale)
        disp('Errore: Il primo input deve essere la Tabella di MATLAB, non un testo.');
        return;
    end

    % --- 2. ELABORAZIONE DEI DATI ---
    % Filtriamo i dati del paziente selezionato
    is_paziente = string(Database_finale.ID_Paziente) == string(ID_Paziente);
    Dati_Paziente = Database_finale(is_paziente, :);
    
    if isempty(Dati_Paziente)
        disp('Errore: Paziente non trovato nel database.');
        return;
    end
    
    % Filtriamo i dati del gruppo di controllo (sani) per fare il confronto
    is_controllo = string(Database_finale.Gruppo_sano_patologico) == "Controllo";
    Controlli = Database_finale(is_controllo, :);
    
    % --- 3. CREAZIONE DEL FILE DI TESTO ---
    nome_file = sprintf('Referto_%s.txt', string(ID_Paziente));
    fid = fopen(nome_file, 'w');
    
    % Intestazione
    fprintf(fid, '========================================\n');
    fprintf(fid, '       REFERTO OCULOMOTORIO LAB\n');
    fprintf(fid, '========================================\n');
    fprintf(fid, 'Paziente: %s\n', ID_Paziente);
    fprintf(fid, 'Gruppo Clinico: %s\n\n', string(Dati_Paziente.Gruppo_sano_patologico(1)));
    
    % Calcolo e stampa delle metriche
    fprintf(fid, '--- CONFRONTO METRICHE VS SANI ---\n');
    
    lat_paz = mean(Dati_Paziente.Latenza_ms, 'omitnan');
    lat_ctrl = mean(Controlli.Latenza_ms, 'omitnan');
    fprintf(fid, 'Latenza Media: %.1f ms (Media Controllo: %.1f ms)\n', lat_paz, lat_ctrl);
    
    err_paz = mean(Dati_Paziente.Error_Rate_Perc, 'omitnan');
    err_ctrl = mean(Controlli.Error_Rate_Perc, 'omitnan');
    fprintf(fid, 'Tasso di Errore: %.1f%% (Media Controllo: %.1f%%)\n\n', err_paz, err_ctrl);
    
    % Conclusione clinica di base
    fprintf(fid, '--- CONCLUSIONE AUTOMATICA ---\n');
    if lat_paz > lat_ctrl * 1.2
        fprintf(fid, 'ATTENZIONE: Rilevato rallentamento oculomotorio significativo.\n');
    else
        fprintf(fid, 'Profilo oculomotorio nei limiti della norma.\n');
    end
    
    % Chiusura del file
    fclose(fid);
    disp(['Referto creato con successo: ' nome_file]);
    
end