class UchprocStudentAttendanceController < ApplicationController
  before_action :require_user
  before_action :get_context

  include Api::V1::UchprocStudentAttendance


  def create
  end

  def update
    errors = []
    kvd = CourseExt.attendance_kvd(params[:kvd])
    topics = UchprocTopic.where("isu_tblvdpstkr.kvd = ?", kvd).order(:dtzap)
    if topics
      header = self.checkTopics(topics)
    end
    if header
      data = params[:attendance]
      data.map do |item, value|
        @student = UchprocStudentAttendance.find(item[:id])
        if @student
          item[:data].map do |it, value|
            num = it[:topicNumber].to_i
            num = num - 1
            if header[num]
              if it[:value] == 'н' && @student[:"cpos#{it[:topicNumber]}"] != 'н'
                @student[:itjurkrss] = @student[:itjurkrss].to_i + 1
                @student[:itjurkrs] = @student[:itjurkrs].to_i + 1
                if !self.update_std_total_attendance(@student.kst, @student.chruchgod, @student[:itjurkrss])
                  errors << "Can't increment  attendance of std: #{it[:id]}"
                end
              elsif it[:value] != 'н' && @student[:"cpos#{it[:topicNumber]}"] == 'н'
                @student[:itjurkrss] = @student[:itjurkrss].to_i - 1
                @student[:itjurkrs] = @student[:itjurkrs].to_i - 1
                if !self.update_std_total_attendance(@student.kst, @student.chruchgod, @student[:itjurkrss])
                  errors << "Can't increment  attendance of std: #{it[:id]}"
                end
              end
              if it[:value] == ' '  && @student[:"cpos#{it[:topicNumber]}"] != ' '
                @student[:itjurkrv] = @student[:itjurkrv].to_i - 1
              elsif  it[:value] != ' '  && @student[:"cpos#{it[:topicNumber]}"] == ' '
                @student[:itjurkrv] = @student[:itjurkrv].to_i + 1
              end
              @student[:"cpos#{it[:topicNumber]}"] = it[:value]
            else
              errors << "Topic by number #{it[:topicNumber]} is not editable"
            end
          end
          if !@student.save
            render json: {error: " can't save attendance"}, status: 400
          end
        else
          errors << "Student by id: #{item[:id]} not found!"
        end
      end
      if errors.length ==0
        render json: {message: " attendance saved successfully"}, status: 200
      else
        render json:{errors: errors},status: 400
      end
    else
      render json: {error: " wrong topic attendance"}, status: 400
    end
  end

  def destroy
  end

  # @API List account admins
  #
  # A paginated list of the admins in the account
  #
  # @argument user_id[] [[Integer]]
  #   Scope the results to those with user IDs equal to any of the IDs specified here.
  #
  # @returns [IsuGrp]
  def index

  end

  def show

  end


  def checkTopics(topics)
    header=[]
    topics.map do |item|
      if((Date.today - Date.parse(item.dtzap.to_s)).to_i < 3)
        header.push(true )
      else
        header.push(false )
      end
    end
    header
  end




  def attendance
    kvd = CourseExt.attendance_kvd(params[:kvd])
    grp_id = params[:grp_id]
    topics = UchprocTopic.where("isu_tblvdpstkr.kvd = ?", kvd).order(dtzap: :desc)
    header = self.checkTopics(topics)
    locale = @current_user.locale
    locale ||= @domain_root_account.default_locale
    if locale == "en"
      locale = @domain_root_account.default_locale
    end
    select_columns = "isu_tblvdtstkr.* , isu_std.isu_std_id, isu_std.nst , isu_std.kzc"
    if locale == "tj"
      select_columns = "isu_tblvdtstkr.* , isu_std.isu_std_id, isu_std.nstt as nst, isu_std.kzc"
    end
    data = UchprocStudentAttendance.select(select_columns).order('nst')
                                   .joins(:uchproc_student)
                                   .where("isu_tblvdtstkr.kvd = ?" , kvd )
    if locale == "tj"
      data.map do |d|
        d.nst = Uchproc::UchprocHelper.convert_to_utf8(d.nst.strip)
      end
    end
    render :json => attendancess_json(data, header, @current_user, @sessions, [])
  end

  def update_std_total_attendance(std_id, academic_year, value)
    if value < 0
      value = 0
    end
    if UchprocStudentAttendance.where(:kst => std_id, :chruchgod => academic_year).update_all(:itjurkrss => value)
      return true
    else
      return false
    end
  end
end
