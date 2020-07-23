*&---------------------------------------------------------------------*
*& Report ZPROOTA_FRM
*& SPTA uses a report containing callback forms which are called to
*& handle and run inside parallel tasks.
*& BEFORE_RFC and AFTER_RFC: they are run in main LUW.
*& IN_RFC: it runs in a new LUW for each parallel task.
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
report zproota_frm.
form f_before_rfc ##CALLED
  using
    p_before_rfc_imp     type spta_t_before_rfc_imp
  changing
    p_before_rfc_exp     type spta_t_before_rfc_exp
    pt_rfcdata           type spta_t_indxtab
    p_failed_objects     type spta_t_failed_objects
    p_objects_in_process type spta_t_objects_in_process
    p_user_param ##PERF_NO_TYPE.

  zcl_proota_framework=>before_rfc(
    exporting
      p_before_rfc_imp     = p_before_rfc_imp
    changing
      pt_rfcdata           = pt_rfcdata
      p_failed_objects     = p_failed_objects
      p_before_rfc_exp     = p_before_rfc_exp
      p_objects_in_process = p_objects_in_process
      p_user_param         = p_user_param ).

endform.

form f_in_rfc ##CALLED
  using
    p_in_rfc_imp  type spta_t_in_rfc_imp
  changing
    p_in_rfc_exp  type spta_t_in_rfc_exp
    p_rfcdata     type spta_t_indxtab.

* Force synchronous update
* This is the most efficient method for parallel processing
* since no update data will be written to the DB but rather
* stored in memory.
* This statement must be reissued after each COMMIT WORK !!!!
  set update task local.
  zcl_proota_framework=>in_rfc(
    exporting
      p_in_rfc_imp = p_in_rfc_imp
    changing
      p_in_rfc_exp = p_in_rfc_exp
      p_rfcdata    = p_rfcdata ).

* Don't forget to COMMIT your data, because if you don't, the
* RFC will end with an automatic rollback and data written to the
* database will be lost.
  commit work.

endform.

form f_after_rfc ##CALLED
  using
    p_rfcdata            type spta_t_indxtab
    p_rfcsubrc           type sy-subrc
    p_rfcmsg             type spta_t_rfcmsg
    p_objects_in_process type spta_t_objects_in_process
    p_after_rfc_imp      type spta_t_after_rfc_imp
  changing
    p_after_rfc_exp      type spta_t_after_rfc_exp
    p_user_param ##PERF_NO_TYPE.

  " SPTA returns P_RFCSUBRC <> 0 when something happens. (Probably values from SPTA_RFC_SUBRC in SPTA type pool)
  " P_RFCMSG should be recorded too in application log. (Maybe values from SPTA_RFC_SUBRC_TXT in SPTA type pool)

  zcl_proota_framework=>after_rfc(
    exporting
      p_rfcdata            = p_rfcdata
      p_rfcsubrc           = p_rfcsubrc
      p_rfcmsg             = p_rfcmsg
      p_objects_in_process = p_objects_in_process
      p_after_rfc_imp      = p_after_rfc_imp
    changing
      p_after_rfc_exp      = p_after_rfc_exp
      p_user_param         = p_user_param ).

endform.
