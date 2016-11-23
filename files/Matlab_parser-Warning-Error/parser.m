% Skript parser.m
%
% Tento skript zpracovava uzivatelem vybrany soubor, ktery z neho tridi
% podle klicovych slov WARNING a Error. Vystupem pote je nekolik souboru s
% nazvem _Warning_cislo.fileFormat a _Error....fileFormat, (fileFormat viz
% nize), ktere obsahuji cisla uzlu, resp. cisla elementu. Prefix techto 
% souboru se da nastavit pomoci promennych maskWarning a maskError. 
% Pocet vystupnich souboru je dan podle toho, kolik je WARNING cisel a druhu 
% Error ve vstupnim souboru. 
% Paklize se chce uzivatel vyhnout vstupnimu oknu pro vyber souboru a chce 
% vstupni soubor zadavat rucne musi v tomto souboru zakomentovat odstavec 
% od msgFile = {}, po if ~jeVybrano vcetne if a od komentovat radek s 
% inputFile = 'Pevnost_05_shell.msg'. 

% Vytvoril: Ondrej Tucek


clc
clear all;

inputFile = 'Pevnost_05_shell.msg'


maskWarning  = '_Warning_';     % prefix pro soubory s warningy, napr. _Warning_11436.txt
maskError  = '_';               % prefix pro soubory s errory, napr. _Error at weld seam modelling.txt
fileFormat = '.txt';            % do jakeho formatu budeme ukladat vystupni soubory


i = 24;                 % od jakeho radku budeme tridit
dataWar = {-1,[-1]};    % bude obsahovat v prvnim sloupci cislo warningu, v druhem 1D vektor cisel uzlu nebo stringu
dataErr = {'',[-1]};    % bude obsahovat v prvnim sloupci string (char) erroru, v druhem 1D vektor cisel uzlu nebo stringu (char)


% ========================  Vstupni okno pro vyber souboru==========================
msgFile = {};
obsah_adresare = dir(pwd);	% nacteme vsechny nazvy podadresaru a souboru v zadanem adresari do pole struktur
k = 1;

% Tento FOR cykl slouzi k vyberu vsech souboru s priponou .msg
for obsah_adr = obsah_adresare' 
    if (obsah_adr.isdir == 0) & (strfind(obsah_adr.name,'.msg') ~= 0)
        msgFile{k} = obsah_adr.name;        
        k = k+1;
    end
end

% openFile ... cislo, ktere urcuje v cell msgFile ktery soubor chceme otevrit
% jeVybrano  ... je 0 (= jestli jsme nic nevybrali - cancel) nebo 1 (= jsme vybrali - ok) 
[openFile,jeVybrano] = listdlg('PromptString','Vyberte soubor:',...
                'SelectionMode','single',...
                'ListString',msgFile);
 
 if ~jeVybrano      % jestlize jsme soubor nevybrali ukoncime tento skript
     break;
 else               % jinak nacteme nami vybrani soubor
     inputFile = msgFile{openFile}
 end
 
            
% =============================  Nacteni dat  ======================================
iFile = fopen( inputFile, 'r' );
if ( iFile < 0)
    fprintf(2,' ======================================================\n');
    fprintf(2,' ==== Nepodarilo se otevrit vstupni soubor.        ====\n');
    fprintf(2,' ==== Vypocet byl predcasne ukoncen!               ====\n');
    fprintf(2,' ======================================================\n');
    break;
end

n = 0;
while ~feof(iFile)	% ze vstupniho souboru nacteme data do struktury cell, viz promenna data
    n = n + 1;
    data{n,1} = fgets(iFile);   % read in one line
end
fclose( iFile );


% =============================  Parsing  ==========================================
sizeData = size(data);

while ( i <= sizeData(1) )
    %   =================== Warnings ===============================================
    if strfind(data{i},'WARNING')                           % najdeme-li Warning tak
    	[sW idWar] = strread(data{i},'%s %d');              % zjistime cislo warningu (= idWar)
        idx = ismember( cell2mat(dataWar(:,1)), idWar);     % a jestli uz ho mame ulozene ve strukture dataWar

        if ( 1 && all(idx == 0) )                           % kdyz ne (tj. je to nove cislo warningu), tak
            dataWar{end+1,1} = idWar;                       % ho (idWar) pridame na konec naseho seznamu
            line = data{i+1};                               % z dalsi radky zjistime cislo elementu 
            elLabel = line(isstrprop(line,'digit'));
            if ~isempty(elLabel)                            % kdyz jde o cislo, 
                dataWar{end,2}(end+1) = str2num(elLabel);   % tak jej pridame na konec 1D pole
            else                                            % kdyz ne, tak je to string
                dataWar{end,2}(end+1) = {line};             % a ten opet pridame na konec seznamu.
            end
        else                                                % V pripade ze uz mame v dataWar cislo warningu, 
            line = data{i+1};                               % ale ne cislo elementu, tak z dalsi radky 
            elLabel = line(isstrprop(line,'digit'));        % jej zjistime.
            if ~isempty(elLabel)                            % Je-li to cislo, 
                dataWar{find(idx),2}(end+1) = str2num(elLabel); % ulozime jej na konec 1D vektoru k patricnemu warningu (viz find(idx))
            else                                            % jinak je to string 
                dataWar{find(idx),2}(end+1) = {line};       % a opet jej ulozime na konec seznamu.
            end
        end        
    %   =================== Errors =================================================
    elseif strfind(data{i},'Error')                         % Popis je stesny jako vyse u Warningu
        str = data{i};
        idxE = strcmp(dataErr(:,1),str(6:end));             % s tim, ze zde porovnavame nazvy erroru. 

        if ( 1 && all(idxE == 0) )
            dataErr{end+1,1} = str(6:end);
            line = data{i+1};
            elLabel = line(isstrprop(line,'digit'));
            if ~isempty(elLabel)
                dataErr{end,2}(end+1) = str2num(elLabel);
            else
                dataErr{end,2}(end+1) = {line};
            end
        else
            line = data{i+1};
            elLabel = line(isstrprop(line,'digit'));
            if ~isempty(elLabel)
                dataErr{find(idxE),2}(end+1) = str2num(elLabel);
            else
                dataErr{find(idxE),2}(end+1) = {line};
            end
        end
    end     % End of if strfind(data{i},'WARNING')
	i = i + 1;
end


%   =================== Vypis Warningu do vystupnich souboru =======================
dataWar(1,:) = [];
pocetWar = size(dataWar);
for i = 1:pocetWar(1)
    oFile = fopen( strcat(maskWarning, num2str( dataWar{i} ), fileFormat), 'w' );
    if ( oFile < 0)
        fprintf(2,' =================================================================\n');
        fprintf(2,' ==== Nepodarilo se ulozit vysledky do souboru %s*%s ====\n',maskWarning,fileFormat);
        fprintf(2,' =================================================================\n');
        return;
    end
    if iscell(dataWar{i,2})                         % zjistime zda jde o 1D vektor cisel nebo stringu
        for j = 1:length(dataWar{i,2})
            fprintf(oFile,'%s',dataWar{i,2}{j});
        end
    else
        v = dataWar{i,2};
        for j = 1:length(dataWar{i,2})
            fprintf(oFile,'%d \r\n',v(j));
        end
    end
    fclose( oFile );
end


%   =================== Vypis Erroru do vystupnich souboru =========================
dataErr(1,:) = [];
pocetErr = size(dataErr);
for i = 1:pocetErr(1)
    oFile = fopen( strcat(maskError,'Error', dataErr{i}, fileFormat), 'w' );
    if ( oFile < 0)
        fprintf(2,' =================================================================\n');
        fprintf(2,' ==== Nepodarilo se ulozit vysledky do souboru %s*%s ====\n',maskError,fileFormat);
        fprintf(2,' =================================================================\n');
        return;
    end
    if iscell(dataErr{i,2})                         % zjistime zda jde o 1D vektor cisel nebo stringu
        for j = 1:length(dataErr{i,2})
            fprintf(oFile,'%s',dataErr{i,2}{j});
        end
    else
        v = dataErr{i,2};
        for j = 1:length(dataErr{i,2})
            fprintf(oFile,'%d \r\n',v(j));
        end
    end
    fclose( oFile );
end

    
fprintf('\n==================  <strong>V S E  P R O B E H L O  V  P O R A D K U.</strong>  ==================\n\n');
fprintf(' Vysledky najdete v souborech <strong>%s</strong>*%s a <strong>_Error</strong>*%s \n',maskWarning,fileFormat,fileFormat);
fprintf(' %s\n\n', pwd);

