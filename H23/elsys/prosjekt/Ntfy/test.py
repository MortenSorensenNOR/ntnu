import requests

requests.post("https://ntfy.sh/ELSYS_GP_15",
    data="🌡️ Temperatur har oversteget 11°C".encode(encoding='utf-8'),
    headers={
        "Title": "Temperatur varsling",
        "Attach": "https://nest.com/view/yAxkasd.jpg",
        "Priority": "urgent"
})
