clear;
fea_dir =  'C:\Users\Михаил\Desktop\Тест пороговых значений\code\'; % Feature files list
config_name = 'C:\Users\Михаил\Desktop\Тест пороговых значений\code\vad.cfg'; %
fid = fopen(config_name, 'rt');
filenames = textscan(fid, '%q %q');
fclose(fid);
filenames = cellfun(@(x) fullfile(fea_dir, x),...  %# Prepend path to files
                       filenames, 'UniformOutput', false);
fid1 = fopen('VadStatistic.txt', 'w'); 
fid2 = fopen('Vadcoeff.txt', 'w');
costmin = 100000;
kmin=0;
Statresult = zeros(10,5);
for k=1:100;
Stat = zeros(10,5); %% Столбцы: 1 - true; 2 - false; 3 - err1; 4 - err2;
thrmin = 0;
err1all = 0;
err2all=0;
for i=1:size(filenames{1},1);
    true = 0;
    err2 = 0;
    err1 = 0;
    false1 = 0;
   data = htkread(char(filenames{1}(i)));
   vadCol = 9;
   vad_mean = mean(data(vadCol,:));
   A = data(vadCol,:);
   vad_min = min(A(A>0));
   %% vad_thr = vad_mean*5/5;
   vad_thr = vad_mean-(vad_mean-vad_min)*(k/100); %% формула определения порога
   Stat(i,5) = vad_thr;
   toDelete = data(vadCol,:)<=vad_thr;
    %% сюда надо вставить модификацию массива с учетом минимального размера паузы и минимального размера речи. 
   toDelete_manual = false(size(toDelete));
   fid = fopen(char(filenames{2}(i)), 'rt');
    pauses_t = textscan(fid, '%s');
   pauses = double.empty(0);
    for j=1:size(pauses_t{1},1)
        pauses = cat(2,pauses, str2num(char(pauses_t{1}(j))));
    end
    pauses = pauses + 1;
    for j=1:size(pauses,2)
       toDelete_manual(pauses(1,j))=1; 
    end
    fclose(fid);
    
    if size(toDelete_manual,2)>size(toDelete)
      toDelete_manual = toDelete_manual(1,1:size(toDelete,2)); %%Выравнивание размеров массивов
    end
  
    for j=1:size(toDelete_manual,2)
    if (toDelete_manual(1,j) == toDelete(1,j))&& (toDelete(1,j) == 1) 
       %% true = true + 1; 
        Stat(i,1) = Stat(i,1) +1;
    end
    if (toDelete_manual(1,j) == toDelete(1,j))&& (toDelete(1,j) == 0) 
      %%  false1 = false1 + 1; 
    Stat(i,2) = Stat(i,2) +1 ;
    end
    if (toDelete_manual(1,j) ~= toDelete(1,j))&& (toDelete_manual(1,j) == 1) 
      %%  err2 = err2 + 1; 
    Stat(i,4) = Stat(i,4) + 1 ;
    end
    if (toDelete_manual(1,j) ~= toDelete(1,j))&& (toDelete_manual(1,j) == 0) 
      %%  err1 = err1 + 1; 
    Stat(i,3) = Stat(i,3) + 1 ;
    end
   %% num = err1 + err2 + false1 + true;
    end
  %%  true = true / size(pauses,2); %% верно определенные паузы, %
   %% false1 = false1 / (j-size(pauses,2)); %% верно определенная речь, %
   %% err2 = err2 / size(pauses,2); %% определили речь, а там пауза
    %% err1 - определили паузу, а там речь. 
err1all=err1all+Stat(i,3);
err2all=err2all+Stat(i,4);
end
cost = err1all*0.2+err2all*0.8;
if (cost<costmin)
  Statresult = Stat;
  kmin = k;
  costmin = cost;
end
fprintf(fid2,'Коэффициент k= %d\r\n', k);
fprintf(fid2,'Стоимостная Функция %d\r\n', cost);
fprintf(fid2,'  %d\r\n','');
end
fprintf(fid1,'Коэффициент k= %d\r\n', kmin);
for i=1:10;
fprintf(fid1,'Тест № %d\r\n', i);
fprintf(fid1,'Пороговое значение  %d\r\n', Statresult(i,5));
fprintf(fid1,'Правильно определенные паузы  %d\r\n', Statresult(i,1));
fprintf(fid1,'Правильно определенная речь %d\r\n', Statresult(i,2));
fprintf(fid1,'Ошибка первого рода  %d\r\n', Statresult(i,3));
fprintf(fid1,'Ошибка второго рода  %d\r\n', Statresult(i,4));
fprintf(fid1,'  %d\r\n','');
%%fprintf(fid1,'Суммарная ошибка первого рода  %d\r\n', err1all);
%%fprintf(fid1,'Суммарная ошибка второго рода  %d\r\n', err2all);
%%fprintf(fid1,'Стоимостная функция  %d\r\n', costmin);
end
 fclose(fid1);
 fclose(fid2);
 %i = size(toDelete,2);
 %X = 1:i; Y = [data(vadCol,:)]; plot (X, Y);
 %hold on   
 %plot([size(toDelete)], [Statresult(1,5) Statresult(1,5)]);
    %% Графики: Рисует график 10 аудиозаписи c выставленным на ней оптимальным порогом.