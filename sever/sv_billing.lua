function GetBillingsForUI(jobName)
    local candidates = {
        { table = 'randol_billing', jobField = 'society', amountField = 'amount', employeeField = 'sender', customerField = 'receiver' },
        { table = 'randol_billing', jobField = 'job', amountField = 'amount', employeeField = 'sender', customerField = 'receiver' },
        { table = 'randol_billing', jobField = 'society', amountField = 'price', employeeField = 'sender', customerField = 'receiver' },
        { table = 'randol_billing', jobField = 'job', amountField = 'price', employeeField = 'sender', customerField = 'receiver' }
    }

    for _, cfg in ipairs(candidates) do
        local ok, rows = pcall(function()
            return MySQL.query.await(
                ('SELECT `%s` as job_name, `%s` as amount, `%s` as employee_name, `%s` as customer_name, created_at FROM `%s` WHERE `%s` = ? ORDER BY created_at DESC LIMIT ?')
                    :format(cfg.jobField, cfg.amountField, cfg.employeeField, cfg.customerField, cfg.table, cfg.jobField),
                { jobName, Config.MaxBillingRows or 25 }
            )
        end)

        if ok and rows then
            return rows
        end
    end

    return {}
end

exports('GetBillingsForUI', GetBillingsForUI)
