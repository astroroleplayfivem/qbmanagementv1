Themes = Themes or {}

function GetBusinessThemeByJob(jobName)
    local business = Businesses and Businesses[jobName] or nil
    if business and business.theme and Themes[business.theme] then
        return Themes[business.theme]
    end

    return Themes.mechanic or {
        id = 'default',
        label = 'Default',
        accent = '#3b82f6',
        accentSoft = 'rgba(59, 130, 246, 0.18)',
        panel = '#10151d',
        panel2 = '#151b24',
        text = '#f3f4f6',
        muted = '#9ca3af',
        icon = '??'
    }
end
