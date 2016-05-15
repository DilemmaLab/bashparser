#!/bin/bash 
printf "Model\tPrice\n" > mobiles.csv; # Header
(
while read line 
	do price='None' # Задаем стартовое пустое значение цены на случай отсутствия Модели
	IFS=' ' read -a array <<< "$line" # Разбили название Модели на слова и положили в массив
	search_string="$(echo "$line" | sed s/' '/'+'/g)" # Сформировали поисковую строку из названия Модели
	content=$(wget http://torg.mail.ru/search/?q=\""$search_string"\" -q -O - | iconv -f 'cp1251' -t 'utf8') 
	# Получили содержимое web-страницы и сохранили его в переменную
	mobile="$(echo "$content" | grep -n -e '<a href=\"http://torg.mail.ru/mobilephones/\" class=\"preview-card-line__breadcrumbs-item-link js-ustat_link js-ustat_link_catalog\">Сотовые телефоны</a></li>' -e '<a href=\"http://torg.mail.ru/planshety/\" class=\"preview-card-line__breadcrumbs-item-link js-ustat_link js-ustat_link_catalog\">Планшеты</a>' | head -1 | awk -F ':' '{print $1}')" 
# Проверили по заголовку раздела каталога, действительно ли это телефон или планшет, а не аксесуар; 
# взяли первую строку (как предположительно наиболее релевантную) 
# и положили в переменную номер этой строки
	if [ ! -z "$mobile" ] # Если строка не пуста, т.е. телефон или планшет действительно найден
		then model="$(echo "$content" | sed -n "$mobile"',$p' | grep '<div class=\"preview-card-line__title-text\">' | head -1 | sed s/'<b class=\"match_found\">'/''/g | sed s/'<\/b>'/''/g | sed s/'<div class=\"preview-card-line__title-text\">'/''/g | sed s/'<\/div>'/''/g )" 
	# 1. Получили название модели, идущее после строки с номером mobile 
	# и соответствующее телефону или планшету, 
	# которому и принадлежал заголовок раздела каталога в строке с номером с номером mobile;
		boolean='True' # 2. Присвоили проверочной переменной значение 'True' 
		for namepart in "${array[@]}" # Теперь ищем все части имени искомой модели 
		# (расположенные в массиве) в названии модели (переменная model), 
		# полученном из контента web-страницы (переменная content)
		do 
			if [ -z "$(echo $model | grep -i -w "$namepart")" ] 
				then boolean='False' 
				# Если какая-либо часть имени искомой модели не найдена,
				# то результат поисковой выдачи считаем не релевантным => 
				# Выводим output -> price==None
			fi 
		done 
		if [ $boolean = "True" ] # Если все части имени искомой модели найдены
			then price="$(echo "$content" | sed -n "$mobile"',$p' | grep '<span class=\"preview-card-line__price-value\">' | head -1 | awk -F'<span class=\"preview-card-line__price-value\">' '{print $2}' | sed s/'<\/span>'/''/g )" 
			# Получаем цену модели
		fi 
	fi 
	printf "%s\t%s\n" "$line" "$price" # Выводим результат 
	done < './parse_mobile' >> mobiles.csv;
	# Данные input - из 'parse_mobile'; данные output - в файл .csv
	)& # Fork процессов
# Dynamical Checking of Progress:
# 1) Number of Current Lines in File
(var1="$(less mobiles.csv | wc -l)"; total="$(less parse_mobile | wc -l)"; while [ $var1 -lt $total ]; do echo -ne "Proceeded\t"$var1"\tlines\tfrom\t"$total"\r"; var1="$(less mobiles.csv | wc -l)"; sleep 0.1; done; echo -ne "\n";
# 2) Status_Bar
printf '|%.0s' $(eval "echo {1.."$(echo "$var")"}"); echo ''; )
