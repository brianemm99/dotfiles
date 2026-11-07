hl.layer_rule({ name = "qs-blur",    match = { namespace = "^qs:" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "qs-no-anim", match = { namespace = "^qs:" }, no_anim = true })
hl.layer_rule({ name = "qs-private", match = { namespace = "^qs:(notifications|osd)$" }, no_screen_share = true })
