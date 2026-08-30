function referto_clinico(Database_finale, ID_Paziente)
    
    % 1. CONTROLLI DI SICUREZZA
    % Controllo se mancano gli input (es. se premiamo Run per sbaglio)
    if nargin < 2
        disp('Errore: Devi fornire sia il database che l''ID del paziente.');
        return;
    end
    
    % Controllo se il database caricato è davvero una tabella
    if ~istable(Database_finale)
        disp('Errore: Il database deve essere una Tabella.');
        return;
    end

    % 2. FILTRAGGIO DEI DATI
    % Isolo solo le righe del database uguali al paziente che ho scelto
    is_paziente = string(Database_finale.ID_Paziente) == string(ID_Paziente);
    Dati_Paziente = Database_finale(is_paziente, :);
    
    % Fermo tutto se il paziente non esiste (tabella vuota)
    if isempty(Dati_Paziente)
        disp('Errore: Paziente non trovato.');
        return;
    end
    
    % Isolo le righe dei soggetti sani (Controllo) per fare il paragone
    is_controllo = string(Database_finale.Gruppo_sano_patologico) == "Controllo";
    Controlli = Database_finale(is_controllo, :);
    
    % 3. CREAZIONE DEL FILE DI TESTO
    % Creo il file .txt con il nome del paziente e lo apro in scrittura ('w')
    nome_file = sprintf('Referto_%s.txt', string(ID_Paziente));
    fid = fopen(nome_file, 'w');
    
    % Scrivo il titolo e i dati base del paziente usando fprintf
     fprintf(fid, '    REFERTO OCULOMOTORIO LAB\n');
    fprintf(fid, 'Paziente: %s\n', ID_Paziente);
    fprintf(fid, 'Gruppo Clinico: %s\n\n', string(Dati_Paziente.Gruppo_sano_patologico(1)));
    
    % 4. CALCOLO E SCRITTURA DELLE METRICHE
    fprintf(fid, '--- CONFRONTO METRICHE VS SANI ---\n');
    
    % Calcolo la latenza media ignorando eventuali errori del macchinario ('omitnan')
    lat_paz = mean(Dati_Paziente.Latenza_ms, 'omitnan');
    lat_ctrl = mean(Controlli.Latenza_ms, 'omitnan');
    fprintf(fid, 'Latenza Media: %.1f ms (Media Controllo: %.1f ms)\n', lat_paz, lat_ctrl);
    
    % Calcolo la percentuale di errore media ignorando i valori nulli
    err_paz = mean(Dati_Paziente.Error_Rate_Perc, 'omitnan');
    err_ctrl = mean(Controlli.Error_Rate_Perc, 'omitnan');
    fprintf(fid, 'Tasso di Errore: %.1f%% (Media Controllo: %.1f%%)\n\n', err_paz, err_ctrl);
    
    % 5. CONCLUSIONE AUTOMATICA
    fprintf(fid, '--- CONCLUSIONE AUTOMATICA ---\n');
    
    % Regola clinica: se il paziente è più lento del 20% rispetto ai sani
    if lat_paz > lat_ctrl * 1.2
        fprintf(fid, 'ATTENZIONE: Rilevato rallentamento oculomotorio significativo.\n');
    else
        fprintf(fid, 'Profilo oculomotorio nei limiti della norma.\n');
    end
    
    % 6. CHIUSURA E SALVATAGGIO
    % Chiudo il file per liberare la memoria di MATLAB
    fclose(fid);
    
    % Avviso finale nella console
    disp(['Referto creato con successo: ' nome_file]);
    
end