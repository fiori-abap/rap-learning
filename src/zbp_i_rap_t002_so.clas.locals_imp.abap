CLASS lcl_transaction_buffer DEFINITION
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

*/
* 一条 PUBLIC SECTION.
*
* 一条尚未写入数据库的前台更新数据。
*
* update_addon_status / update_addon_remark
* 用来区分前台实际更新了哪个字段。
*/
    TYPES:
      BEGIN OF ty_update_buffer,
        sales_order         TYPE zrap_t002_addon-sales_order,
        sales_order_item    TYPE zrap_t002_addon-sales_order_item,

        addon_status        TYPE zrap_t002_addon-addon_status,
        addon_remark        TYPE zrap_t002_addon-addon_remark,

        update_addon_status TYPE abap_bool,
        update_addon_remark TYPE abap_bool,
      END OF ty_update_buffer,

*/
* 同一个销售订单明细在一次事务中只保留一条。
*/
      tt_update_buffer TYPE HASHED TABLE OF ty_update_buffer
        WITH UNIQUE KEY sales_order sales_order_item.

    CLASS-DATA gt_update_buffer
      TYPE tt_update_buffer.

    CLASS-METHODS clear.

ENDCLASS.


CLASS lcl_transaction_buffer IMPLEMENTATION.

  METHOD clear.

    CLEAR gt_update_buffer.

  ENDMETHOD.

ENDCLASS.



CLASS lhc_SalesOrderItem DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING
      REQUEST requested_authorizations
      FOR SalesOrderItem
      RESULT result.

    METHODS update
      FOR MODIFY
      IMPORTING
        entities
          FOR UPDATE SalesOrderItem.

    METHODS read
      FOR READ
      IMPORTING
                keys
                  FOR READ SalesOrderItem
      RESULT    result.

    METHODS lock
      FOR LOCK
      IMPORTING
        keys
          FOR LOCK SalesOrderItem.

ENDCLASS.



CLASS lhc_SalesOrderItem IMPLEMENTATION.

  METHOD get_global_authorizations.

*/
* 当前学习程序中，
* 暂时允许所有用户执行 Update。
*/
    IF requested_authorizations-%update =
       if_abap_behv=>mk-on.

      result-%update =
        if_abap_behv=>auth-allowed.

    ENDIF.

  ENDMETHOD.



  METHOD update.

*/
* RAP Update 阶段不直接写数据库。
*
* 这里只把前台传来的修改内容，
* 放入当前事务的内存缓存。
*/
    LOOP AT entities INTO DATA(ls_entity).

*/
* AddonStatus 和 AddonRemark 都没被更新时，
* 不需要加入缓存。
*/
      IF ls_entity-%control-AddonStatus <>
           if_abap_behv=>mk-on
         AND
         ls_entity-%control-AddonRemark <>
           if_abap_behv=>mk-on.

        CONTINUE.

      ENDIF.

*/
* 检查同一个订单明细是否已经进入缓存。
*/
      READ TABLE
        lcl_transaction_buffer=>gt_update_buffer
        ASSIGNING FIELD-SYMBOL(<ls_buffer>)
        WITH TABLE KEY
          sales_order =
            ls_entity-SalesOrder
          sales_order_item =
            ls_entity-SalesOrderItem.

*/
* 第一次更新这条明细时，
* 先建立一条缓存记录。
*/
      IF sy-subrc <> 0.

        INSERT VALUE #(
          sales_order =
            ls_entity-SalesOrder

          sales_order_item =
            ls_entity-SalesOrderItem
        )
        INTO TABLE
          lcl_transaction_buffer=>gt_update_buffer
        ASSIGNING
          <ls_buffer>.

      ENDIF.

*
* 前台实际传了 AddonStatus 时才更新。
*
* 只接受：
* 勾选   → 1
* 未勾选 → 0
*
* 即使前台传来空值或其他值，
* 后台也统一保存为0。
*/
      IF ls_entity-%control-AddonStatus =
           if_abap_behv=>mk-on.

        <ls_buffer>-addon_status =
          COND #(
            WHEN ls_entity-AddonStatus = '1'
              THEN '1'
            ELSE
              '0'
          ).

        <ls_buffer>-update_addon_status =
          abap_true.

      ENDIF.

*/
* 前台实际传了 AddonRemark 时才更新。
*/
      IF ls_entity-%control-AddonRemark =
           if_abap_behv=>mk-on.

        <ls_buffer>-addon_remark =
          ls_entity-AddonRemark.

        <ls_buffer>-update_addon_remark =
          abap_true.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.



  METHOD read.

*/
* 没有请求主键时直接返回。
*/
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

*/
* 从 Interface CDS 读取销售订单明细和
* 已保存的 Addon 数据。
*/
    SELECT FROM zi_rap_t002_so
      FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE SalesOrder =
              @keys-SalesOrder
        AND SalesOrderItem =
              @keys-SalesOrderItem
      INTO TABLE @DATA(lt_sales_order_item).

*/
* CDS Entity 和 RAP Read Result 中的
* 普通业务字段名称一致，
* 因此直接按照同名字段转换即可。
*
* 这里不要使用：
* MAPPING TO ENTITY
*
* 因为当前 Behavior Definition
* 没有定义 Persistence Mapping。
*/
    result =
      CORRESPONDING #(
        lt_sales_order_item
      ).

*/
* 如果当前事务中已经修改，
* 但还没有执行 Save，
* 则使用事务缓存覆盖数据库旧值。
*
* 这样能够保证：
* Update 后再 Read 时看到的是新值。
*/
    LOOP AT
      lcl_transaction_buffer=>gt_update_buffer
      INTO DATA(ls_buffer).

*/
* RAP Read Result 自带名为 ENTITY 的 Key。
* 明确指定它，可以消除当前黄色警告。
*/
      READ TABLE result
        ASSIGNING FIELD-SYMBOL(<ls_result>)
        WITH TABLE KEY entity COMPONENTS
          SalesOrder =
            ls_buffer-sales_order
          SalesOrderItem =
            ls_buffer-sales_order_item.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_buffer-update_addon_status =
           abap_true.

        <ls_result>-AddonStatus =
          ls_buffer-addon_status.

      ENDIF.

      IF ls_buffer-update_addon_remark =
           abap_true.

        <ls_result>-AddonRemark =
          ls_buffer-addon_remark.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.



  METHOD lock.

*/
* 当前阶段暂时不实现数据库锁。
*
* 单用户学习测试不受影响。
* 后续再为 ZRAP_T002_ADDON
* 建立 Lock Object，并在这里加锁。
*/
  ENDMETHOD.

ENDCLASS.



CLASS lsc_ZI_RAP_T002_SO DEFINITION
  INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS finalize
        REDEFINITION.

    METHODS check_before_save
        REDEFINITION.

    METHODS save
        REDEFINITION.

    METHODS cleanup
        REDEFINITION.

    METHODS cleanup_finalize
        REDEFINITION.

ENDCLASS.



CLASS lsc_ZI_RAP_T002_SO IMPLEMENTATION.

  METHOD finalize.

*/
* 当前没有 Finalize 处理。
*/
  ENDMETHOD.



  METHOD check_before_save.

*/
* 当前没有额外保存前检查。
*
* AddonStatus 已在 Update 阶段
* 统一转换为0或1。
*/
  ENDMETHOD.



  METHOD save.

*/
* 没有任何修改时不访问数据库。
*/
    IF lcl_transaction_buffer=>gt_update_buffer
         IS INITIAL.

      RETURN.

    ENDIF.

*/
* 保存一份本次事务缓存，
* 后续所有数据库处理都使用这份数据。
*/
    DATA(lt_update_buffer) =
      lcl_transaction_buffer=>gt_update_buffer.

*/
* 读取数据库中已经存在的 Addon 数据。
*
* 已存在：
*   后续执行更新
*
* 不存在：
*   后续执行新增
*/
    DATA lt_existing
      TYPE SORTED TABLE OF zrap_t002_addon
      WITH UNIQUE KEY
        sales_order
        sales_order_item.

    SELECT FROM zrap_t002_addon
      FIELDS *
      FOR ALL ENTRIES IN @lt_update_buffer
      WHERE sales_order =
              @lt_update_buffer-sales_order
        AND sales_order_item =
              @lt_update_buffer-sales_order_item
      INTO TABLE @lt_existing.

*/
* 取得统一的更新时刻。
*
* 同一次保存的所有记录使用相同时间戳。
*/
    DATA lv_timestamp TYPE timestampl.

    GET TIME STAMP FIELD lv_timestamp.

*/
* 最终写入数据库的数据。
*/
    DATA lt_save
      TYPE STANDARD TABLE OF zrap_t002_addon
      WITH EMPTY KEY.

    DATA ls_addon
      TYPE zrap_t002_addon.

    LOOP AT lt_update_buffer
      INTO DATA(ls_update).

      CLEAR ls_addon.

*/
* 先读取数据库中已有的数据，
* 防止只修改一个字段时覆盖另一个字段。
*/
      READ TABLE lt_existing
        INTO ls_addon
        WITH TABLE KEY
          sales_order =
            ls_update-sales_order
          sales_order_item =
            ls_update-sales_order_item.

*/
* 数据库中不存在时，
* 创建新的 Addon 记录。
*/
      IF sy-subrc <> 0.

        ls_addon-client =
          sy-mandt.

        ls_addon-sales_order =
          ls_update-sales_order.

        ls_addon-sales_order_item =
          ls_update-sales_order_item.

*/
* 新建时默认未勾选。
*/
        ls_addon-addon_status =
          '0'.

        ls_addon-created_by =
          sy-uname.

        ls_addon-created_at =
          lv_timestamp.

      ENDIF.

*/
* 只更新前台实际修改过的字段。
*/
      IF ls_update-update_addon_status =
           abap_true.

        ls_addon-addon_status =
          ls_update-addon_status.

      ENDIF.

      IF ls_update-update_addon_remark =
           abap_true.

        ls_addon-addon_remark =
          ls_update-addon_remark.

      ENDIF.

*/
* 新增和更新都刷新最后修改信息。
*/
      ls_addon-last_changed_by =
        sy-uname.

      ls_addon-last_changed_at =
        lv_timestamp.

      ls_addon-local_last_changed_at =
        lv_timestamp.

      APPEND ls_addon
        TO lt_save.

    ENDLOOP.

*/
* 根据数据库主键执行 Upsert：
*
* 已存在 → UPDATE
* 不存在 → INSERT
*
* 这里只写 ZRAP_T002_ADDON，
* 绝不更新 VBAK 或 VBAP。
*/
    MODIFY zrap_t002_addon
      FROM TABLE @lt_save.

*/
* 这里绝对不要写：
*
* COMMIT WORK
*
* RAP Framework 会统一控制事务提交。
*/
  ENDMETHOD.



  METHOD cleanup.

*/
* 保存结束或事务中止后，
* 清空当前事务缓存。
*/
    lcl_transaction_buffer=>clear( ).

  ENDMETHOD.



  METHOD cleanup_finalize.

*/
* Finalize 阶段发生异常时，
* 同样清空事务缓存。
*/
    lcl_transaction_buffer=>clear( ).

  ENDMETHOD.

ENDCLASS.
