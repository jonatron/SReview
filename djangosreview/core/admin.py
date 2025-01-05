from django.contrib import admin
from core.models import (Commentlog, ConfigOverrides, Corrections, Events, Properties, RawFiles, Rooms,
    Speakers, SpeakersEvents, SpeakersTalks, Talks, Tracks, Users)


class CommentlogAdmin(admin.ModelAdmin):
    pass


admin.site.register(Commentlog, CommentlogAdmin)

class ConfigOverridesAdmin(admin.ModelAdmin):
    pass

admin.site.register(ConfigOverrides, ConfigOverridesAdmin)

class CorrectionsAdmin(admin.ModelAdmin):
    pass

admin.site.register(Corrections, CorrectionsAdmin)

class EventsAdmin(admin.ModelAdmin):
    pass

admin.site.register(Events, EventsAdmin)

class PropertiesAdmin(admin.ModelAdmin):
    pass

admin.site.register(Properties, PropertiesAdmin)

class RawFilesAdmin(admin.ModelAdmin):
    pass

admin.site.register(RawFiles, RawFilesAdmin)

class RoomsAdmin(admin.ModelAdmin):
    pass

admin.site.register(Rooms, RoomsAdmin)

class SpeakersAdmin(admin.ModelAdmin):
    pass

admin.site.register(Speakers, SpeakersAdmin)

class SpeakersEventsAdmin(admin.ModelAdmin):
    pass

admin.site.register(SpeakersEvents, SpeakersAdmin)

class SpeakersTalksAdmin(admin.ModelAdmin):
    pass

admin.site.register(SpeakersTalks, SpeakersAdmin)

class TalksAdmin(admin.ModelAdmin):
    pass

admin.site.register(Talks, SpeakersAdmin)

class TracksAdmin(admin.ModelAdmin):
    pass

admin.site.register(Tracks, TracksAdmin)

class UsersAdmin(admin.ModelAdmin):
    pass

admin.site.register(Users, UsersAdmin)
