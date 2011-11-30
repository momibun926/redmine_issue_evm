module GlossaryPortHelper


  def glossary_csvout(csv, ic, ary)
    csv << ary.collect {|c|
      begin
        ic.iconv(c.to_s)
      rescue
        c.to_s
      end
    }
  end
  
  def glossary_to_csv(terms)
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = Term.export_params.collect {|prm|
        label_param(prm)
      }

      glossary_csvout(csv, ic, headers)
      
      # csv lines
      terms.each do |term|
        fields = Term.export_params.collect {|prm|
          term.param_to_s(prm)
        }
        glossary_csvout(csv, ic, fields)
      end
    end
    export
  end


  def glossary_from_csv(portinfo, projid)
    line_count = 0
    begin
      ic = Iconv.new('UTF-8', portinfo.in_encoding)

      raise l(:error_file_none)	if (!portinfo.import_file)
      FCSV::parse(portinfo.import_file) { |row|
        line_count += 1
        next	if (portinfo.is_first_comment and line_count == 1)
        next	if (row.empty?)

        name = row[portinfo.param_col('name')]        
        raise sprintf(l(:error_no_name), t("label.name"))	unless name

        name = ic.iconv(name)
        term = Term.find(:first,
                         :conditions => ["project_id = #{projid} AND name = :name",
                                         {:name=>name}])
        if (term)
          portinfo.upterm_num += 1
        else
          term = Term.new(:name => name, :project_id => projid)
          portinfo.newterm_num += 1
        end

        for col in 0 ... row.size
          prm = portinfo.col_param(col)
          next	unless prm
          val = ic.iconv(row[col].to_s)
          case prm
          when 'name'
          when 'category'
            cat = TermCategory.find_by_name(val)
            unless (cat)
              cat = TermCategory.new(:name => val)
              unless (cat.save)
                raise l(:error_create_term_category)
              end
              portinfo.cat_num += 1
            end
            term['category_id'] = cat.id
          else
            term[prm] = val
          end
        end
	unless (term.save)
          raise l(:error_create_term)
        end
      }
    rescue => evar
      portinfo.err_string = evar.to_s
      if (0 < line_count)
        portinfo.err_string += sprintf(l(:error_csv_import_row), line_count)
      end
    end
  end
  
end
