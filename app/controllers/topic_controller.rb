class TopicController < ApplicationController
  before_action :require_user
  before_action :get_context
  include Api::V1::UchprocTopic

  def create
    res= params[:topic]
    res[:obsh] = res[:lek].to_i + res[:prak].to_i + res[:lab].to_i + res[:kmd].to_i + res[:sem].to_i
    if self.validateTopic(res)
      kvd = CourseExt.attendance_kvd(params[:kvd])
      sis_user = @current_user.pseudonyms.where("sis_user_id like 'tch_%'").first
      if sis_user && sis_user_id = sis_user.sis_user_id
        uchproc_user_id = sis_user_id[4..-1]
      else
        uchproc_user_id = 0
      end
      if kvd
        next_id = UchprocTopic.get_next_id
        course = Course.find(params[:kvd])
        if course.workflow_state == 'completed' || course.conclude_at < Time.now.utc || course.enrollment_term.end_at < Time.now.utc
          return render json: {error: "This course was completed"}, :status => :bad_request
        end
        if !course.grants_any_right?(@current_user, :topic_add) && !course.account.grants_any_right?(@current_user, :topic_add)
          return render json: {error: "You do not have permission"}, :status => :bad_request
        end
        topic = UchprocTopic.create(:kdn => next_id, :isu_tblvdpstkr_id => next_id, :kvd => kvd,:ctema =>res[:tema], :nkolch =>res[:lek],
                               :nkolchsem =>res[:sem], :nkolchlab=>res[:lab], :nkolchprak=>res[:prak],
                               :nkolchkmdro=>res[:kmd],:nkolchv=>res[:obsh], :cnzap=>next_topic_number(kvd), :dtzap => Time.now,
                               :kst => uchproc_user_id, :chruchgod => course.enrollment_term.name,
                               :vchaccess => course.course_code[0..1], :ad_client_id => 1000000,
                               :ad_org_id => 1000000, :createdby => 100, :updatedby => 100,
                               :isu_tblvdtkr_id => kvd, :isu_sot_id => uchproc_user_id)
        if topic.save
          data = subject_json(topic, @current_user,@sessions,[])
          return render(:json => data)
        else
          return render json: {error: " Can't add topic"}, :status => :bad_request
        end
      else
        render json: {error: " Can't add topic"}, :status => :bad_request
      end
    else
      render json: {error: " Can't add topic"}, :status => :bad_request
    end
  end

  def update
    @topic = UchprocTopic.find(params[:id])
    if @topic
      course = CourseExt.course_by_att_kvd(@topic.kvd)
      res=params[:topic]
      res[:obsh] = res[:lek].to_i + res[:prak].to_i + res[:lab].to_i + res[:kmd].to_i + res[:sem].to_i
      if !course
        return render json: {error: " Can't find course"}, :status => :bad_request
      elsif !course.grants_any_right?(@current_user, :topic_edit) && !course.account.grants_any_right?(@current_user, :topic_edit)
        return render json: {error: "You do not have permission"}, :status => :bad_request
      end

      if(self.validateTopic(res) && self.topicIsEditable(@topic))
        @topic.ctema= res[:tema]
        @topic.nkolchsem = res[:sem]
        @topic.nkolchlab = res[:lab]
        @topic.nkolchprak = res[:prak]
        @topic.nkolchkmdro = res[:kmd]
        @topic.nkolch = res[:lek]
        @topic.nkolchv = res[:obsh]
        @topic.save
        render :json => subject_json(@topic,@current_user,@sessions,[])
      else
        render json: {error: " Can't edit topic"}, :status => :bad_request
      end
    else
      render json: {error: " Can't find topic"}, status: 404
    end
  end

  def destroy
    topic = UchprocTopic.find(params[:id])
    if topic
      course = CourseExt.course_by_att_kvd(topic[:kvd].to_i)
      if !course
        return render json: {error: " Can't find course"}, :status => :bad_request
      elsif !course.grants_any_right?(@current_user, :topic_delete) && !course.account.grants_any_right?(@current_user, :topic_delete)
        return render json: {error: "You do not have permission"}, :status => :bad_request
      elsif topic.cnzap.strip.to_i != next_topic_number(topic.kvd).strip.to_i - 1
        return render json: {error: "This is not the last topic"}, :status => :bad_request
      elsif !self.topic_attendance_empty(params[:id])
        return render json: {error: "Attendance not empty"}, :status => :bad_request

      end
      if(self.topicIsEditable(topic) and self.topic_attendance_empty(params[:id]))
        if topic.destroy
          render json: {message: "Topic deleted"}, status: 200
        else
          render json: {message: "Something went wrong"}, :status => :bad_request
        end

      end
    else
      render json: {error: "Topic not found!"}, status: 404
    end

  end


  def index
    #data = IsuStd.all
    #data = IsuTema.take(100)
    #render :json => isu_subjects_json(data,@current_user,@sessions,[])
  end

  def show
    isu_subject_id = params[:isu_subject_id]
    data = UchprocTopic.find(isu_subject_id)
    render :json => isu_subject_json(data,@current_user,@sessions,[])
  end
  def subjects_by_kvd
    kvd = CourseExt.attendance_kvd(params[:kvd])
    data = UchprocTopic.where("isu_tblvdpstkr.kvd = ?", kvd).order(dtzap: :desc)
    header = self.checkTopics(data)
    render :json => subjects_json(data,header,@current_user,@sessions,[])
  end

  def checkTopics(topics)
    header=[]
    topics.map do |item|
      if((Date.today - Date.parse(item.dtzap.to_s)).to_i < 1)
        header<< true
      else
        header<< false
      end
    end
    header
  end
  def topicIsEditable(topic)
    if((Date.today - Date.parse(topic.dtzap.to_s)).to_i < 1)
      return true
    else
      return false
    end
  end
  def validateTopic(topic)
    if(topic[:obsh] < 1 || !topic[:lek].to_s.match(/[0-5]{1}/) || !topic[:sem].to_s.match(/[0-5]{1}/) || !topic[:prak].to_s.match(/[0-5]{1}/) || !topic[:lab].to_s.match(/[0-5]{1}/) || !topic[:kmd].to_s.match(/[0-5]{1}/) || topic[:tema]=="" )
      return  false
    end
    return true
  end
  def topic_attendance_empty(id)
    topic = UchprocTopic.find(id)
    if topic
      column_name = 'cpos'+ topic.cnzap.strip
      where = "trim(" + column_name + ") != ? and kvd = ?"
      attendace = UchprocStudentAttendance.where(where, '', topic.kvd).first
      if attendace
        return false
      else
        return true
      end
    else
      return false
    end
  end
  def next_topic_number(kvd)
    topic_number = UchprocTopic.select("COALESCE(MAX(CAST(cnzap AS INTEGER)), 0) + 1 AS next_id").where(:kvd => kvd).order(:next_id).first
    if topic_number.next_id < 10
      return "  #{topic_number.next_id}"
    elsif topic_number.next_id < 100
      return " #{topic_number.next_id}"
    else
      return "#{topic_number.next_id}"
    end
  end
end
