local Translations = {
    error = {
        no_access = 'You do not have access to this management panel.',
        invalid_amount = 'Invalid amount.',
        insufficient_funds = 'Insufficient society funds.',
        player_not_found = 'Player not found.',
        no_nearby_player = 'No nearby player found.',
        invalid_grade = 'Invalid grade.'
    },
    success = {
        bonus_sent = 'Bonus paid successfully.',
        note_added = 'Note added.',
        employee_updated = 'Employee updated.',
        employee_hired = 'Employee hired.',
        employee_fired = 'Employee fired.',
        society_deposit = 'Society deposit successful.',
        society_withdraw = 'Society withdraw successful.'
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
