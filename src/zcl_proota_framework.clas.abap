class zcl_proota_framework definition
  public
  final
  create private .

  public section.

    class-methods before_rfc
      importing
        !p_before_rfc_imp     type spta_t_before_rfc_imp
      changing
        !pt_rfcdata           type spta_t_indxtab
        !p_failed_objects     type spta_t_failed_objects
        !p_before_rfc_exp     type spta_t_before_rfc_exp
        !p_objects_in_process type spta_t_objects_in_process
        !p_user_param         type data .
    class-methods in_rfc
      importing
        !p_in_rfc_imp type spta_t_in_rfc_imp
      changing
        !p_in_rfc_exp type spta_t_in_rfc_exp
        !p_rfcdata    type spta_t_indxtab .
    class-methods after_rfc
      importing
        !p_rfcdata            type spta_t_indxtab
        !p_rfcsubrc           type sy-subrc
        !p_rfcmsg             type spta_t_rfcmsg
        !p_objects_in_process type spta_t_objects_in_process
        !p_after_rfc_imp      type spta_t_after_rfc_imp
      changing
        !p_after_rfc_exp      type spta_t_after_rfc_exp
        !p_user_param         type data .
    class-methods run
      importing
        !parallel_code type ref to zif_proota_parallel_code .
  protected section.
  private section.

    types:
      begin of gty_user_params,
        cls_name type string, "Not using seoclsname because local class naming doesn't fit on it, only global classes.
        instance type ref to zif_proota_parallel_code,
      end of gty_user_params .
    types:
      begin of gty_context_input,
        cls_name type gty_user_params-cls_name,
        data     type xstring,
      end of gty_context_input .

    constants gc_callback_program type programm value 'YTVBP_OOPTA_PRG' ##NO_TEXT.
endclass.



class zcl_proota_framework implementation.


  method after_rfc.
    data:
      context_output type ref to data,
      parallel_code  type ref to zif_proota_parallel_code.
    field-symbols:
      <ctx>   type data,
      <param> type gty_user_params.

    assign p_user_param to <param>.
    parallel_code = <param>-instance.
    parallel_code->context_output(
      importing
        er_data = context_output
    ).
    assign context_output->* to <ctx>.

    call function 'SPTA_INDX_PACKAGE_DECODE'
      exporting
        indxtab = p_rfcdata
      importing
        data    = <ctx>.
    if p_rfcsubrc is initial.
*   No RFC error occured
      parallel_code->merge( ctx = context_output ).
    endif.

* Error handling
* Note: An incorrect way to handle application specific errors
*       may lead to an infinite loop in the application, because
*       if an error is returned to the task manager that object
*       ist rescheduled in the FAILED_OBJS table and is supposed
*       to be reprocessed again which may lead to another application
*       error. The only way out of this behaviour is to set
*       the flag 'NO_RESUBMISSION_ON_ERROR' to the task manager
*       and store an error message in the application's error log.
*       Hoever there are situations where is is appropriate
*       to not set this flag and thus allow a resubmission of those
*       objects:
*       - If one aRFC processes 100 objects and the task fails
*         return an application_error to the task manager.
*         Then reprocess each failed_objs one by one. If a task
*         fails that processes only one object then return
*         no_error to the task manager and store the error
*         in the application's log.

  endmethod.


  method before_rfc.
    data:
      ld_failed_obj     like line of p_failed_objects,
      context_input     type zif_proota_parallel_code=>gty_context_input,
      parallel_code     type ref to zif_proota_parallel_code,
      wa_obj_in_process like line of p_objects_in_process.
    field-symbols:
      <context_input> type data,
      <param>         type gty_user_params.

    assign p_user_param to <param>.
    parallel_code = <param>-instance.
* Check if there are objects from previously failed tasks left ...
    read table p_failed_objects index 1 into ld_failed_obj.
    if sy-subrc = 0.
* Yes there are.
* Take first object and delete it from list of failed objects
      delete p_failed_objects index 1.
      append initial line to p_objects_in_process assigning field-symbol(<obj_in_process>).
      <obj_in_process> = ld_failed_obj.
    else.
* No there aren't.
* Take objects from regular input list of objects
      parallel_code->fetch_block_data(
*        EXPORTING
*          block_id    =
        importing
          ev_block_id = wa_obj_in_process-obj_id
          e_data      = context_input
      ).

      if wa_obj_in_process-obj_id is not initial.
        append wa_obj_in_process to p_objects_in_process.
      endif.
    endif.

* If there is (currently) nothing to do, clear the
* START_RFC field and leave the form.
* This informs the task manager that no rfc has to be started.
* If there are no more RFCs in process this also ends
* the processing of the task manager
* If there are still RFCs in process the BEFORE_RFC form
* will be invoked after each RFC has been received to give
* the application an opportunity to launch new RFCs that have been
* waiting on the RFC that was just received.
    if p_objects_in_process is initial.
      p_before_rfc_exp-start_rfc = abap_false.
      return.
    endif.

* Convert the input data into the INDX structure
* that is needed for the RFC
    if context_input is bound.
      assign context_input->* to <context_input>.
      data wa_fw_ctx_input type gty_context_input.
      wa_fw_ctx_input-cls_name = <param>-cls_name.
      export data from <context_input> to data buffer wa_fw_ctx_input-data.
      call function 'SPTA_INDX_PACKAGE_ENCODE'
        exporting
          data    = wa_fw_ctx_input
        importing
          indxtab = pt_rfcdata.
    endif.

* Inform task manager that an RFC can be started from the
* data compiled
    p_before_rfc_exp-start_rfc = abap_true.
  endmethod.


  method in_rfc.
    data:
      parallel        type ref to zif_proota_parallel_code,
      context_input   type ref to data,
      context_output  type ref to data,
      ls_fw_ctx_input type gty_context_input.
    field-symbols:
      <input_context>  type data,
      <output_context> type data.

* Unpack RFC input data (that has been packed in the BEFORE_RFC form)
    call function 'SPTA_INDX_PACKAGE_DECODE'
      exporting
        indxtab = p_rfcdata
      importing
        data    = ls_fw_ctx_input.
    create object parallel type (ls_fw_ctx_input-cls_name).
    parallel->context_input( importing er_data = context_input ).
    assert
      condition context_input is bound.
    assign context_input->* to <input_context>.
    parallel->context_output( importing er_data = context_output ).
    assert
      condition context_output is bound.
    assign context_output->* to <output_context>.
* Unpack app data
    import data = <input_context> from data buffer ls_fw_ctx_input-data.
* Begin processing of RFC
    parallel->worker(
      exporting
        i_ctx = context_input
      importing
        e_ctx = context_output
    ).
* Repack output data for AFTER_RFC form
    call function 'SPTA_INDX_PACKAGE_ENCODE'
      exporting
        data    = <output_context>
      importing
        indxtab = p_rfcdata.

  endmethod.


  method run.
    data:
      lv_server_group type spta_rfcgr value 'parallel_generators',
      lv_max_tasks    type sy-index value 1,
      ls_user_param   type gty_user_params.

    ls_user_param-cls_name = cl_abap_classdescr=>get_class_name( p_object = parallel_code ).
    ls_user_param-instance = parallel_code.

    call function 'SPTA_PARA_PROCESS_START_2'
      exporting
        server_group             = lv_server_group
        max_no_of_tasks          = lv_max_tasks
        before_rfc_callback_form = 'F_BEFORE_RFC'
        in_rfc_callback_form     = 'F_IN_RFC'
        after_rfc_callback_form  = 'F_AFTER_RFC'
        callback_prog            = gc_callback_program
*       SHOW_STATUS              = ' '
*       RESOURCE_TIMEOUT         = 600
*       TASK_CALL_MODE           = 1
      changing
        user_param               = ls_user_param
      exceptions
        invalid_server_group     = 1
        no_resources_available   = 2
        others                   = 3.
    if sy-subrc <> 0.
*   Implement suitable error handling here
    endif.
  endmethod.
endclass.
